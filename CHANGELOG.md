# Changelog

このリポジトリで学習用に加えた変更を記録します。

## 2026-08-27

### `asm.py`

- アセンブル時のエラー表示を、`ファイル名:行番号: error: ...` 形式にしました。
- エラー行のソースコードと、原因箇所を示す `^` を表示するようにしました。
- 未定義ラベルや未定義定数で Python の `NameError` traceback が出ないようにしました。
- 未定義シンボルに近いラベルがある場合、`hint: did you mean ...?` を表示するようにしました。
- オペランド不足、オペランド過多、不正レジスタ、メモリアクセス書式不正をアセンブラのエラーとして表示するようにしました。
- `.BYTE` / `.WORD` / `.DWORD` の引数不足を検出するようにしました。
- 即値命令の20ビット範囲外を検出するようにしました。
- `STDI R8, [basetime]` のような `[label]` 表記は、作者版 `asm.py` と同じく受け付けるようにしました。
- 式評価時の `eval()` は、`__builtins__` を空にして実行するようにしました。

### `asmx.py`

- エラー表示を読みやすくした補助版アセンブラとして、`asmx.py` を追加しました。
- 元の `asm.py` と同じ使い方で、`python3 asmx.py os.asm` のように実行できます。

確認コマンド:

```sh
python3 asm.py os.asm
python3 asmx.py os.asm
python3 -m py_compile asm.py
python3 -m py_compile asmx.py
```

確認結果:

```text
Wrote os.bin (790529 bytes)
```

### `os.asm`

- `_get__nth_token_end` のようにアンダースコアが1つ多いラベル参照を、`_get_nth_token_end` に修正しました。
- tick 数カウント用の割り込み処理を追加した際、`vector_table` を途中で `0xFF800` に置くと後続の `.ADDR 0xB0000` へ戻れないため、割り込みベクタテーブルをソース末尾側へ移動しました。
- 書籍ページ内に見当たらない `do_date:` 本体として、`LDDI R8, [basetime]`、`SYSCALL 11`、`JPI cmdloop` を追加しました。

確認したエラー表示例:

```text
os.asm:185: error: undefined symbol '_get__nth_token_end'
        JPZI    _get__nth_token_end
                ^^^^^^^^^^^^^^^^^^^
hint: did you mean '_get_nth_token_end'?
```
