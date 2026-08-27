import re
import sys
import difflib

# コメント処理：クオート外の ';' だけをコメント開始として扱う
_COMMENT_SPLIT_RE = re.compile(r';(?=(?:[^"]*"[^"]*")*[^"]*$)')
_IDENT_RE = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\b')
source_name = '<input>'

def strip_comment_outside_quotes(s: str) -> str:
    if not s:
        return s
    parts = _COMMENT_SPLIT_RE.split(s, maxsplit=1)
    return parts[0] if parts else s

# グローバル
symbol_table = {}
binary_code = bytearray()
instruction_size = 4  # 32ビット = 4バイト

# 第1パスで未解決の .DEF を保留
_deferred_defs = []   # list[tuple[name, expr, lineno, raw_line]]

class AsmError(Exception):
    pass

# ===== オペコード辞書 =====
type0_opdic = {'NOP':0b0000, 'HALT':0b0001, 'RET':0b0010, 'IRET':0b0011,
               'EI':0b0100, 'DI':0b0101}
type1_opdic = {'PUSH':0b0000, 'POP':0b0001, 'INC':0b0010, 'DEC':0b0011,
               'NOT':0b0100,
               'JP':0b1000, 'CALL':0b1001, 'JPZ':0b1010,  'JPNZ':0b1011,
               'JPO':0b1100, 'JPNO':0b1101, 'JPU':0b1110, 'JPNU':0b1111}
type2_opdic = {'MOV':0b0000, 'ADD':0b0001, 'SUB':0b0010, 'ADT':0b0011,
               'SBT':0b0100, 'MUL':0b0101, 'DIV':0b0110, 'MOD':0b0111,
               'AND':0b1000, 'OR':0b1001, 'XOR':0b1010}
type3_opdic = {'LDB':0b0000, 'STB':0b0001, 'LDW':0b0010, 'STW':0b0011,
               'LDD':0b0100, 'STD':0b0101}
type4_opdic = {'MOVI':0b0000, 'ADDI':0b0001, 'SUBI':0b0010, 'ADTI':0b0011,
               'SBTI':0b0100, 'MULI':0b0101, 'DIVI':0b0110, 'MODI':0b0111,
               'ANDI':0b1000, 'ORI':0b1001, 'XORI':0b1010}
type5_opdic = {'LDBI':0b0000, 'STBI':0b0001, 'LDWI':0b0010, 'STWI':0b0011,
               'LDDI':0b0100, 'STDI':0b0101}
type6_opdic = {'SYSCALL':0b0000,
               'JPI':0b1000, 'CALLI':0b1001, 'JPZI':0b1010, 'JPNZI':0b1011,
               'JPOI':0b1100, 'JPNOI':0b1101, 'JPUI':0b1110, 'JPNUI':0b1111}

registers_dic = {'R0':0b0000, 'R1':0b0001, 'R2':0b0010, 'R3':0b0011,
                 'R4':0b0100, 'R5':0b0101, 'R6':0b0110, 'R7':0b0111,
                 'R8':0b1000, 'R9':0b1001, 'TP':0b1010, 'SP':0b1011,
                 'PC':0b1100, 'PT':0b1101, 'VT':0b1110, 'CR':0b1111}

def print_source_error(lineno: int, raw_line: str, message: str, token: str = None):
    print(f"{source_name}:{lineno}: error: {message}", file=sys.stderr)
    if raw_line is not None:
        print(f"    {raw_line}", file=sys.stderr)
        if token:
            col = raw_line.find(token)
            if col >= 0:
                print(f"    {' ' * col}{'^' * max(1, len(token))}", file=sys.stderr)

def error(lineno: int, raw_line: str, message: str, token: str = None):
    print_source_error(lineno, raw_line, message, token)
    sys.exit(1)

def undefined_symbol_error(name: str, lineno: int, raw_line: str):
    print_source_error(lineno, raw_line, f"undefined symbol '{name}'", name)
    matches = difflib.get_close_matches(name, symbol_table.keys(), n=1, cutoff=0.75)
    if matches:
        print(f"hint: did you mean '{matches[0]}'?", file=sys.stderr)
    sys.exit(1)

def split_operands(s: str):
    return [p.strip() for p in re.split(r'[, \t\[\]]+', s) if p.strip()]

def require_operand_count(parts, count: int, lineno: int, raw_line: str):
    actual = len(parts) - 1
    opcode = parts[0].upper() if parts else ''
    if actual < count:
        error(lineno, raw_line, f"{opcode} のオペランドが足りません（必要: {count}, 実際: {actual}）", opcode)
    if actual > count:
        error(lineno, raw_line, f"{opcode} のオペランドが多過ぎます（必要: {count}, 実際: {actual}）", parts[count + 1])

def register_code(name: str, lineno: int, raw_line: str):
    reg = name.upper()
    if reg not in registers_dic:
        error(lineno, raw_line, f"レジスタ名が不正です: {name}", name)
    return registers_dic[reg]

def require_expression(expr: str, lineno: int, raw_line: str, what: str):
    if not expr.strip():
        error(lineno, raw_line, f"{what} の式がありません", what)
    return expr

def require_directive_expr(s: str, lineno: int, raw_line: str, directive: str):
    fields = s.split(None, 1)
    if len(fields) < 2 or not fields[1].strip():
        error(lineno, raw_line, f"{directive} の引数がありません", directive)
    return fields[1]

def parse_register_expression(s: str, lineno: int, raw_line: str, opcode: str):
    m = re.match(r'\S+\s+([^,\s]+)\s*,\s*(.+)$', s)
    if not m:
        error(lineno, raw_line, f"{opcode} の書式が不正です", opcode)
    return m.group(1), require_expression(m.group(2), lineno, raw_line, opcode)

def parse_expression_operand(s: str, lineno: int, raw_line: str, opcode: str):
    fields = s.split(None, 1)
    if len(fields) < 2:
        error(lineno, raw_line, f"{opcode} のオペランドが足りません（必要: 1, 実際: 0）", opcode)
    return require_expression(fields[1], lineno, raw_line, opcode)

def checked_int(value, lineno: int, raw_line: str, token: str):
    try:
        return int(value)
    except Exception:
        error(lineno, raw_line, f"整数に変換できません: {value}", token)

def checked_imm20(value, lineno: int, raw_line: str, token: str):
    n = checked_int(value, lineno, raw_line, token)
    if n < -0x80000 or n > 0xFFFFF:
        error(lineno, raw_line, f"即値が20ビット範囲外です: {n}", token)
    return n & 0xFFFFF

def eval_expression(exp_str: str, lineno: int = None, raw_line: str = None):
    """
    式文字列の識別子(ラベル/定数名)をsymbol_tableで数値に置換し、evalで評価。
    """
    def _repl(m):
        name = m.group(1)
        if name in symbol_table:
            return str(symbol_table[name])
        # 未定義はそのまま残す（後でevalが失敗 → 呼び出し側で検出）
        return name
    unresolved = [m.group(1) for m in _IDENT_RE.finditer(exp_str)
                  if m.group(1) not in symbol_table]
    if unresolved:
        name = unresolved[0]
        if lineno is not None:
            undefined_symbol_error(name, lineno, raw_line)
        raise AsmError(f"undefined symbol '{name}'")
    exp = _IDENT_RE.sub(_repl, exp_str)
    try:
        return eval(exp, {"__builtins__": {}}, {})
    except Exception as e:
        if lineno is not None:
            error(lineno, raw_line, f"invalid expression '{exp_str}': {e}", exp_str)
        raise AsmError(f"invalid expression '{exp_str}': {e}") from e

def first_pass(source_text: str):
    """第1パス: ラベル収集と概算レイアウト。未解決の.DEFは保留。.ADDR は未解決ならエラー。"""
    global symbol_table
    symbol_table = {}
    loc_counter = 0

    lines = source_text.splitlines()
    for lineno, raw in enumerate(lines, 1):
        s = strip_comment_outside_quotes(raw.strip())
        if not s:
            continue

        # ラベル処理
        if ':' in s:
            label, _, rest = s.partition(':')
            label = label.strip()
            if label:
                symbol_table[label] = loc_counter
            s = rest.strip()
            if not s:
                continue

        # ディレクティブや命令をトークン化（.STRING は後で個別処理）
        opcode = s.split()[0].upper()

        if opcode == '.DWORD':
            loc_counter += 4
        elif opcode == '.WORD':
            loc_counter += 2
        elif opcode == '.BYTE':
            loc_counter += 1
        elif opcode == '.STRING':
            m = re.search(r'"(.*?)"', s)
            if not m:
                error(lineno, raw, ".STRING の書式が正しくありません", ".STRING")
            encoded = m.group(1).encode('utf-8') + b'\x00'
            loc_counter += len(encoded)
        elif opcode == '.DEF':
            m = re.match(r'\.DEF\s+([A-Za-z_][A-Za-z0-9_]*)\s+(.+)$', s, re.IGNORECASE)
            if not m:
                error(lineno, raw, ".DEF の書式が正しくありません", ".DEF")
            name, expr = m.group(1), m.group(2)
            try:
                val = eval_expression(expr)
                symbol_table[name] = val
            except Exception:
                # 前方参照など未解決は保留
                _deferred_defs.append((name, expr, lineno, raw))
        elif opcode == '.ADDR':
            expr = s.split(None,1)[1] if len(s.split(None,1))>1 else ''
            if not expr:
                error(lineno, raw, ".ADDR の引数がありません", ".ADDR")
            # 既知ラベルで評価を試み、失敗したらエラーで中止（前方参照禁止）
            try:
                addr = eval_expression(expr, lineno, raw)
            except Exception:
                error(lineno, raw, f".ADDR の式を評価できません（前方参照禁止）: {expr}", expr)
            if addr < loc_counter:
                error(lineno, raw, f".ADDR が現在位置より小さい値を指定しています: 0x{addr:X} < 0x{loc_counter:X}", expr)
            loc_counter = addr
        else:
            # 命令はすべて 4 バイト
            loc_counter += instruction_size

def second_pass(source_text: str):
    """第2パス: 本アセンブル。冒頭でdeferred .DEFを反復解決。.ADDRは未解決ならエラー。"""
    global binary_code
    binary_code = bytearray()
    loc_counter = 0

    # deferred .DEF を反復解決（解けたものから登録 → 再試行）
    if _deferred_defs:
        unresolved = list(_deferred_defs)
        _deferred_defs.clear()
        progress = True
        while unresolved and progress:
            progress = False
            next_round = []
            for name, expr, lineno, raw in unresolved:
                try:
                    val = eval_expression(expr)
                    symbol_table[name] = val
                    progress = True
                except Exception:
                    next_round.append((name, expr, lineno, raw))
            unresolved = next_round
        if unresolved:
            # ここで解けないものは依存が循環しているか、未定義シンボル
            names = ', '.join(n for n, _, _, _ in unresolved)
            print(f"{source_name}: error: 未解決の .DEF が残っています: {names}", file=sys.stderr)
            for _, expr, lineno, raw in unresolved:
                print_source_error(lineno, raw, f".DEF の式を評価できません: {expr}", expr)
            sys.exit(1)

    lines = source_text.splitlines()
    for lineno, raw in enumerate(lines, 1):
        s = strip_comment_outside_quotes(raw.strip())
        if not s:
            continue

        # ラベルを除去（第1パスで登録済み）
        if ':' in s:
            _, _, s = s.partition(':')
            s = s.strip()
            if not s:
                continue

        if not s:
            continue

        opcode = s.split()[0].upper()

        # ===== 命令のエンコード =====
        # タイプ0
        if opcode in type0_opdic:
            parts = split_operands(s)
            require_operand_count(parts, 0, lineno, raw)
            op_code = type0_opdic[opcode]
            instruction = (0b0000 << 28) | (op_code << 24)
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ1（単一レジスタ or 条件分岐 with レジスタ）
        elif opcode in type1_opdic:
            parts = split_operands(s)
            require_operand_count(parts, 1, lineno, raw)
            op_code = type1_opdic[opcode]
            rd_code = register_code(parts[1], lineno, raw)
            instruction = (0b0001 << 28) | (op_code << 24) | (rd_code << 20)
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ2（レジスタ間）
        elif opcode in type2_opdic:
            parts = split_operands(s)
            require_operand_count(parts, 2, lineno, raw)
            op_code = type2_opdic[opcode]
            rd_code = register_code(parts[1], lineno, raw)
            rs_code = register_code(parts[2], lineno, raw)
            instruction = (0b0010 << 28) | (op_code << 24) | (rd_code << 20) | (rs_code << 16)
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ3（メモリ—レジスタ間: [Rs]）
        elif opcode in type3_opdic:
            # 例: LDB R1, [R2]
            m = re.match(r'([A-Za-z]+)\s+([A-Za-z0-9]+)\s*,\s*\[([A-Za-z0-9]+)\]\s*$', s)
            if not m:
                error(lineno, raw, "メモリアクセス書式が不正です", opcode)
            op_code = type3_opdic[opcode]
            rd, rs = m.group(2).upper(), m.group(3).upper()
            rd_code = register_code(rd, lineno, raw)
            rs_code = register_code(rs, lineno, raw)
            instruction = (0b0011 << 28) | (op_code << 24) | (rd_code << 20) | (rs_code << 16)
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ4（即値）
        elif opcode in type4_opdic:
            op_code = type4_opdic[opcode]
            rd, expr = parse_register_expression(s, lineno, raw, opcode)
            rd_code = register_code(rd, lineno, raw)
            imm = eval_expression(expr, lineno, raw)
            imm20 = checked_imm20(imm, lineno, raw, expr)
            instruction = (0b0100 << 28) | (op_code << 24) | (rd_code << 20) | imm20
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ5（絶対アドレス）
        elif opcode in type5_opdic:
            op_code = type5_opdic[opcode]
            rd, expr = parse_register_expression(s, lineno, raw, opcode)
            rd_code = register_code(rd, lineno, raw)
            imm = eval_expression(expr, lineno, raw)
            imm20 = checked_imm20(imm, lineno, raw, expr)
            instruction = (0b0101 << 28) | (op_code << 24) | (rd_code << 20) | imm20
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # タイプ6（即値のみ：SYSCALL / 即値分岐など）
        elif opcode in type6_opdic:
            op_code = type6_opdic[opcode]
            expr = parse_expression_operand(s, lineno, raw, opcode)
            imm = eval_expression(expr, lineno, raw)
            imm20 = checked_imm20(imm, lineno, raw, expr)
            instruction = (0b0110 << 28) | (op_code << 24) | imm20
            binary_code.extend(instruction.to_bytes(4, 'big'))
            loc_counter += instruction_size

        # ===== ディレクティブ =====
        elif opcode == '.DWORD':
            expr = require_directive_expr(s, lineno, raw, ".DWORD")
            value = eval_expression(expr, lineno, raw)
            try:
                binary_code.extend(checked_int(value, lineno, raw, expr).to_bytes(4, 'big', signed=False))
            except OverflowError:
                error(lineno, raw, ".DWORD の値が大き過ぎます", ".DWORD")
            loc_counter += 4

        elif opcode == '.WORD':
            expr = require_directive_expr(s, lineno, raw, ".WORD")
            value = eval_expression(expr, lineno, raw)
            try:
                binary_code.extend(checked_int(value, lineno, raw, expr).to_bytes(2, 'big', signed=False))
            except OverflowError:
                error(lineno, raw, ".WORD の値が大き過ぎます", ".WORD")
            loc_counter += 2

        elif opcode == '.BYTE':
            expr = require_directive_expr(s, lineno, raw, ".BYTE")
            value = eval_expression(expr, lineno, raw)
            try:
                binary_code.extend(checked_int(value, lineno, raw, expr).to_bytes(1, 'big', signed=False))
            except OverflowError:
                error(lineno, raw, ".BYTE の値が大き過ぎます", ".BYTE")
            loc_counter += 1

        elif opcode == '.DEF':
            # 第2パスではシンボルは確定済み（冒頭で再評価済み）
            pass

        elif opcode == '.STRING':
            m = re.search(r'"(.*?)"', s)
            if not m:
                error(lineno, raw, ".STRING の書式が正しくありません", ".STRING")
            encoded = m.group(1).encode('utf-8') + b'\x00'
            binary_code.extend(encoded)
            loc_counter += len(encoded)

        elif opcode == '.ADDR':
            expr = s.split(None,1)[1] if len(s.split(None,1))>1 else ''
            if not expr:
                error(lineno, raw, ".ADDR の引数がありません", ".ADDR")
            try:
                value = eval_expression(expr, lineno, raw)
            except Exception:
                error(lineno, raw, f".ADDR の式を評価できません（前方参照禁止）: {expr}", expr)
            if value < loc_counter:
                error(lineno, raw, f".ADDR が現在位置より小さい値を指定しています: 0x{value:X} < 0x{loc_counter:X}", expr)
            # 前詰め：0でパディング
            for _ in range(loc_counter, int(value)):
                binary_code.append(0)
            loc_counter = int(value)

        else:
            error(lineno, raw, f"不明な命令/ディレクティブです: {opcode}", opcode)

def assemble(source_code: str, filename: str, input_name: str = '<input>'):
    global source_name
    source_name = input_name
    first_pass(source_code)
    second_pass(source_code)
    with open(filename, 'wb') as f:
        f.write(binary_code)
    print(f"Wrote {filename} ({len(binary_code)} bytes)")

if __name__ == '__main__':
    args = sys.argv
    if len(args) >= 2:
        if args[1].endswith('.asm'):
            sourcefile = args[1]
            outputfile = args[1][:-len('.asm')] + '.bin'
        else:
            print("ファイルの拡張子が .asm ではありません")
            sys.exit(1)
    else:
        print("ソースファイルを指定してください")
        sys.exit(1)

    with open(sourcefile, 'r', encoding='utf-8') as f:
        source_code = f.read()

    assemble(source_code, outputfile, sourcefile)
