# 「いちばんやさしい！OS自作超入門」第4章でつまずいたこと

書籍「いちばんやさしい！OS自作超入門」を読みながら、`os_book_code` の第4章を進めました。

第4章では、これまで単体プログラムを動かしていた流れから、`os.bin` として Simple OS を起動し、OS上で `reg`、`ls`、`exec`、`date` などのコマンドを動かす流れへ進みます。

この記事では、第4章を進める中でつまずいた点と、手元で確認した対応を、書籍の進行順に整理します。

## この記事で使うファイル

今回の記事で使う第4章用のファイルは、リポジトリ内の `chapter4/` ディレクトリにまとめます。

第4章の主な混乱ポイントは、各章ごとの完成版 `os.asm` と、それを動かすための Python ファイルが同じ場所にまとまっていないことでした。

そこで、`chapter4/` には次のファイルを置きます。

- `os.asm`: 第4章の完成版です
- `asm.py`: アセンブラです
- `asmx.py`: エラー表示を読みやすくした補助版アセンブラです
- `emu.py`: `os.bin` を起動するCPUエミュレータです
- `pi.asm`: `exec` コマンド確認用のプログラムです
- `dir/`: `exec` コマンドが参照するディレクトリです

ブログ本文の下書きである `article-draft.md` や `article-wordpress.txt` は、GitHub公開用の `chapter4/` には含めません。

## 第4章 4-2: `emu.py` が `os.bin` 起動用になる

第4章 4-2 では、CPUエミュレータ側で `os.bin` を読み込む形に変更し、`SP` や `PC` の初期値もOS起動用に変わります。

この変更後は、第1章から第3章で使っていたような、次の手順では `hello.bin` を直接実行できません。

```sh
python emu.py hello.bin
```

この時点の `emu.py` は、引数の `hello.bin` ではなく、カレントディレクトリの `os.bin` を読み込む前提になります。

そのため、第4章以降では次のように分けて考えます。

- Simple OS を起動する場合は、`python emu.py` を使います
- `hello.bin` のような単体プログラムを直接確認したい場合は、序盤用の `early.py` を使います
- Simple OS から外部プログラムを実行する場合は、`exec` コマンドが使えるようになってから `dir/` 配下に `.bin` を置いて実行します

4-4 で `exec` コマンドを追加すると、後からOSの中からユーザープログラムを実行できるようになります。

つまり、第4章の途中では一時的に「昔の `hello.bin` 直接実行手順」と「これから作るOS上での `exec` 実行手順」の間にいる、と理解すると混乱しにくいです。

## 第4章の作業前に `git status` を確認する

第4章の脚注には、`git fetch && git checkout v0.2` や `git fetch && git checkout v0.3` のようなコマンドが出てきます。

これらは指定されたタグやブランチの状態へ作業ツリーを切り替える操作なので、手元で編集している `os.asm` や `asm.py` がある場合、内容が上書きされたり、切り替え前にコミットや退避を求められたりします。

実行前に、次のコマンドで作業ツリーの状態を確認しておきます。

```sh
git status
```

自分で編集したファイルがある場合は、先にコミットするか、別名で保存してから `checkout` します。

## 第4章 4-3: ラベル名のタイプミスで Python traceback が出る

`os.asm` をアセンブルすると、ラベル名のタイプミスで次のような Python の traceback が表示されました。

```sh
python asm.py os.asm
```

```text
Traceback (most recent call last):
  File "/Users/noi/wp/os_dev/os_book_code/asm.py", line 340, in <module>
    assemble(source_code, outputfile)
  File "/Users/noi/wp/os_dev/os_book_code/asm.py", line 319, in assemble
    second_pass(source_code)
  File "/Users/noi/wp/os_dev/os_book_code/asm.py", line 249, in second_pass
    imm = eval_expression(' '.join(parts[1:]))
  File "/Users/noi/wp/os_dev/os_book_code/asm.py", line 59, in eval_expression
    return eval(exp)
  File "<string>", line 1, in <module>
NameError: name '_get__nth_token_end' is not defined
```

原因は `os.asm` 側のラベル名のタイプミスでした。

参照している側は、`_get__nth_token_end` になっていました。`get` と `nth` の間にアンダースコアが2つあります。

```asm
JPZI    _get__nth_token_end
```

しかし、定義されているラベルは `_get_nth_token_end` でした。

```asm
_get_nth_token_end:
```

正しくは次のように、アンダースコアは1つです。

```asm
JPZI    _get_nth_token_end
```

エラー表示の確認では、同じ種類の未定義ラベルを意図的に作って、候補表示が出ることも確認しました。

## 補助ツール `asmx.py` を用意する

元の `asm.py` では、即値やラベルを評価するときに Python の `eval()` を使っています。

```python
return eval(exp)
```

ラベル名が `symbol_table` に存在しない場合、その名前が Python の未定義変数として `eval()` に渡されます。その結果、アセンブラとしてのエラーではなく、Python の `NameError` がそのまま表示されていました。

そこで、`asm.py` のエラーメッセージを少し改造した補助ツールとして、`asmx.py` を用意しました。

`asmx.py` の `x` は、`asm.py` の extended 版という意味です。短く入力でき、元の `asm.py` をもとにした補助版だと分かりやすい名前にしています。

使い方は `asm.py` と同じです。

```sh
python asmx.py os.asm
```

元の `asm.py` を直接置き換えず、エラー原因を詳しく見たいときだけ `asmx.py` を使う形にしておくと、書籍の元コードとの差分も追いやすくなります。

`asmx.py` では、gcc や clang のように「どのファイルの何行目で、どの部分が原因か」を見やすくしました。

変更後は、同じタイプミスが次のように表示されます。

```text
os.asm:185: error: undefined symbol '_get__nth_token_end'
        JPZI    _get__nth_token_end
                ^^^^^^^^^^^^^^^^^^^
hint: did you mean '_get_nth_token_end'?
```

見るべき場所が `os.asm` の185行目だと分かり、該当するラベル名にキャレットが付きます。

さらに、`symbol_table` に近い名前のラベルがある場合は、候補も表示します。

今回の改造では、次のようなエラーも Python の traceback ではなく、アセンブラ風のメッセージとして表示するようにしました。

- 未定義ラベル、未定義定数
- 近いラベル候補の表示
- オペランド不足
- オペランド過多
- 不正レジスタ
- メモリアクセス内の不正レジスタ
- `.BYTE` / `.WORD` / `.DWORD` の引数不足
- 即値が20ビット範囲を超えた場合
- `.ADDR` の式エラー
- `.STRING` の書式エラー
- 不明な命令やディレクティブ

例えば、`MOV R0` のようにオペランドが足りない場合は、次のように表示されます。

```text
/tmp/asm-missing-operand.asm:2: error: MOV のオペランドが足りません（必要: 2, 実際: 1）
    MOV R0
    ^^^
```

不正なレジスタ名を書いた場合は、次のように表示されます。

```text
/tmp/asm-bad-reg.asm:2: error: レジスタ名が不正です: RX
    MOV RX, R1
        ^^
```

20ビットに入らない即値を書いた場合は、次のように表示されます。

```text
/tmp/asm-imm-range.asm:2: error: 即値が20ビット範囲外です: 1048576
    MOVI R0, 0x100000
             ^^^^^^^^
```

## `asmx.py` に追加した主な処理

`asmx.py` には、共通のエラー表示関数を追加しました。

```python
def print_source_error(lineno: int, raw_line: str, message: str, token: str = None):
    print(f"{source_name}:{lineno}: error: {message}", file=sys.stderr)
```

未定義シンボルについては、`difflib.get_close_matches()` を使って近いラベル名を探します。

```python
matches = difflib.get_close_matches(name, symbol_table.keys(), n=1, cutoff=0.75)
```

また、命令の処理に入る前に、オペランド数とレジスタ名を検査するヘルパーを追加しました。

```python
def require_operand_count(parts, count: int, lineno: int, raw_line: str):
    ...

def register_code(name: str, lineno: int, raw_line: str):
    ...
```

この変更により、`IndexError` や `KeyError` がそのまま出るケースを減らしています。

通常の `os.asm` は、これまで通りアセンブルできます。

```sh
python3 asmx.py os.asm
```

```text
Wrote os.bin (790529 bytes)
```

Python の文法エラーがないことも確認しました。

```sh
python3 -m py_compile asmx.py
```

このコマンドは、エラーなしで終了しました。

## 第4章 4-4: `exec` コマンドで外部プログラムを実行する

4-4 では、Simple OS に `exec` コマンドを追加します。

ここからは、`hello.bin` や `pi.bin` のようなユーザープログラムを、エミュレータに直接渡すのではなく、Simple OS のプロンプトから起動する流れになります。

実行する `.bin` ファイルは、`dir/` 配下に置きます。

```sh
python asm.py pi.asm
mkdir -p dir
cp pi.bin dir/pi.bin
python emu.py
```

Simple OS が起動したら、プロンプトで次のように入力します。

```text
> exec pi.bin
```

`dir/pi.bin` が無い場合は、次のようなエラーになります。

```text
File open error.
```

## 第4章 4-5: tick 数カウント追加時の `.ADDR` エラー

`os.asm` に tick 数をカウントするための割り込み処理を追加したところ、次のエラーが出ました。

```sh
python asm.py os.asm
```

```text
os.asm:131: error: .ADDR が現在位置より小さい値を指定しています: 0xB0000 < 0xFF865
            .ADDR   0xB0000
                    ^^^^^^^
```

このエラーは、`.ADDR 0xB0000` そのものが間違っているという意味ではありません。

直前に追加した割り込みベクタテーブルを、次のように `0xFF800` へ配置していたことが原因でした。

```asm
; Vector Table
        .ADDR   0xFF800
vector_table:
        .DWORD  int_timer
        .DWORD  int_other
        .DWORD  int_other
        .DWORD  int_other
```

`asm.py` は、ソースコードを上から順番に読みながら、出力ファイル上の現在位置を進めていきます。

そのため、一度 `.ADDR 0xFF800` で現在位置を高い番地へ進めると、そのあとに `.ADDR 0xB0000` で低い番地へ戻ることはできません。

今回の流れは、次のようになっていました。

```text
0x80000  OS本体
0xFF800  割り込みベクタテーブル
0xB0000  システム関数
```

`0xFF800` から `0xB0000` へ戻ろうとしているため、`asm.py` がエラーとして止めていました。

対応として、割り込みベクタテーブルをソースの末尾側へ移動しました。

```text
0x80000  OS本体
0xB0000  システム関数
0xB1000  get_nth_token
0xC0000  keybuffer
0xC1000  tokenbuffer
0xFF800  割り込みベクタテーブル
```

これなら `.ADDR` で指定する番地が常に前へ進むため、アセンブルできます。

なお、テキストを見直すと、図22の下には `os.asm` の末尾にこのコードを追加するという注意書きがあります。

ここを読み落として、図21の直後に続けて書くと、今回のように `.ADDR 0xFF800` のあとで `.ADDR 0xB0000` へ戻ろうとしてエラーになります。

記事では、図22のコードは「その場に挿入するコード」ではなく「ファイル末尾へ追加するコード」として扱う、と書いておくとよさそうです。

修正後は次のように成功しました。

```sh
python3 asm.py os.asm
```

```text
Wrote os.bin (1046544 bytes)
```

`os.bin` のサイズが大きくなっているのは、`.ADDR 0xFF800` まで 0 でパディングされるためです。

## tick 数が増えていることを確認する

タイマー割り込み処理では、`TP` レジスタをインクリメントしています。

```asm
int_timer:
        INC     TP
```

`reg` コマンドで確認すると、`TP` が増えていることが分かりました。

```text
TP: 000000EA
TP: 000001F4
```

`0xEA` は10進数で234、`0x1F4` は10進数で500です。

この値が増えているので、タイマー割り込みごとに `int_timer` が呼ばれ、`INC TP` が実行されていると見てよさそうです。

## 第4章 4-5: `date` コマンド追加時のつまずき

続いて、書籍の図24から図26に従って `date` コマンドを追加したところ、次のエラーが出ました。

```sh
python asm.py os.asm
```

```text
os.asm:3: error: 整数に変換できません: [524717]
        STDI    R8, [basetime]
                  ^^^^^^^^^^
```

書籍の図24では、OS起動時にUNIXタイムを取得して `basetime` に保存するコードとして、次のように書かれています。

```asm
SYSCALL 10
STDI    R8, [basetime]
MOVI    TP, 0
MOVI    VT, vector_table
EI
```

しかし、現在の `asm.py` では、`STDI` は type5 の「絶対アドレスを即値で指定する命令」として実装されています。

そのため、`STDI` の第2オペランドは、`[basetime]` ではなく `basetime` と書く必要があります。

修正後:

```asm
SYSCALL 10
STDI    R8, basetime
MOVI    TP, 0
MOVI    VT, vector_table
EI
```

ここは、自分の打ち間違いというより、書籍上の表記と現在の `asm.py` が受け付ける文法のズレとして整理すると分かりやすいです。

`STB R0, [R1]` のような角括弧付きの書き方は、レジスタが指すアドレスへアクセスする type3 命令で使います。

一方、`STDI R8, basetime` は、ラベル `basetime` のアドレスを即値として命令に埋め込み、そのアドレスへ `R8` の値を書き込む命令です。

## `do_date` ラベルが未定義になる

`STDI` の書き方を直したあと、次は `do_date` が未定義というエラーになりました。

```text
os.asm:84: error: undefined symbol 'do_date'
        JPZI    do_date
                ^^^^^^^
hint: did you mean 'cmd_date'?
```

書籍の図25には、`date` コマンドを判定するコードが載っています。

```asm
; date
        MOVI    R9, cmd_date
        CALLI   cmp_str
        JPZI    do_date
```

これは、入力されたコマンドが `date` と一致したら、`do_date` へジャンプする処理です。

また、図26には `cmd_date` と `basetime` のデータ定義が載っています。

```asm
cmd_date:
        .STRING "date"

basetime:
        .DWORD  0
```

ただし、図24、図25、図26で説明が終わり、その次が第5章に進むのであれば、ジャンプ先である `do_date:` 本体の追加コードは見当たりません。

そのため、図25のコードだけを追加すると、`JPZI do_date` のジャンプ先が存在せず、`undefined symbol 'do_date'` になります。

`SYSCALL 11` の説明から考えると、最低限必要な `do_date:` 本体は次の形になります。

```asm
do_date:
        LDDI    R8, basetime
        SYSCALL 11
        JPI     cmdloop
```

`LDDI R8, basetime` で、OS起動時に保存したUNIXタイムを `basetime` から読み出します。

そのあと `SYSCALL 11` を呼ぶと、エミュレータ側で `R8` の基準時刻と `TP` の tick 数から現在時刻を計算して表示します。

最後に `JPI cmdloop` で Simple OS のコマンド入力待ちへ戻ります。

## `date` 判定を入れる場所

`date` コマンドの判定コードは、未知コマンドのエラー表示より前に置く必要があります。

例えば、`exec` 判定の後、次のエラー表示へ進む前に入れます。

```asm
; exec
        MOVI    R9, cmd_exec
        CALLI   cmp_str
        JPZI    do_exec
; date
        MOVI    R9, cmd_date
        CALLI   cmp_str
        JPZI    do_date

        MOVI    R8, cmd_error1
        SYSCALL 1
```

未知コマンドのエラー表示より後ろに `date` 判定を置くと、`date` と入力しても先にエラー処理へ流れてしまい、`do_date` まで到達しません。

## `date` 追加時の完成形

冒頭部分は次のようにします。

```asm
        .ADDR   0x80000
        SYSCALL 10
        STDI    R8, basetime
        MOVI    TP, 0
        MOVI    VT, vector_table
        EI
        MOVI    R8, start_message
        SYSCALL 1
```

コマンド判定部分には、未知コマンド処理の前に `date` 判定を追加します。

```asm
; date
        MOVI    R9, cmd_date
        CALLI   cmp_str
        JPZI    do_date
```

コマンド実行部分には、書籍のページ内では見当たらなかった `do_date:` 本体を追加します。

```asm
do_date:
        LDDI    R8, basetime
        SYSCALL 11
        JPI     cmdloop
```

データ部分には、書籍の図26どおり `cmd_date` と `basetime` を追加します。

```asm
cmd_date:
        .STRING "date"
basetime:
        .DWORD  0
```

修正後は、アセンブルが成功しました。

```sh
python3 asm.py os.asm
```

```text
Wrote os.bin (1046544 bytes)
```

## 今回のまとめ

第4章では、`emu.py` の役割が単体プログラム実行用から `os.bin` 起動用へ変わります。

そのうえで、`os.asm` にコマンド処理、割り込み処理、ベクタテーブル、データ領域を少しずつ追加していくため、コードを入れる場所が重要になります。

今回特につまずいたのは、次の点です。

- `emu.py` 変更後は `python emu.py hello.bin` では `hello.bin` を直接実行できません
- ラベル名のタイプミスは、元の `asm.py` では Python traceback として出ます
- `.ADDR` は現在位置を低い番地へ戻す用途には使えません
- 図22の割り込みベクタテーブルは、`os.asm` の末尾に追加します
- 書籍の `STDI R8, [basetime]` は、現在の `asm.py` では `STDI R8, basetime` と書く必要があります
- 図24から図26の範囲では、`do_date:` 本体の追加コードは見当たりません

本格的にアセンブラを作り込むなら、式パーサを `eval()` ではなく専用の安全な実装に置き換える方法もあります。

ただ、学習中の補助としては、今回の最低限の診断だけでも、ラベル名や命令の書き間違いをかなり見つけやすくなります。
