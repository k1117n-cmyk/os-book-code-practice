# Chapter 7

「いちばんやさしい！OS自作超入門」第7章の学習用コードです。

第7章では、タスクごとのページテーブルを使い、論理アドレスから物理アドレスへの変換とページフォルトの発生を確認します。

## Files

- `os.asm`: 第7章のOSコード
- `os.bin`: `os.asm` をアセンブルしたOSイメージ
- `emu.py`: 第7章用のCPUエミュレータ
- `asm.py`: 書籍付属のアセンブラ
- `asmx.py`: エラー表示を補助したアセンブラ
- `dump.asm`: 論理アドレスと物理アドレスの比較用プログラム
- `pagefault.asm`: ページフォルト確認用プログラム
- `hello_task.asm`: `taskexec` 確認用プログラム
- `dir/`: Simple OS の `exec` / `taskexec` から読む `.bin` ファイル

## Build

```sh
python3 asmx.py os.asm
python3 asmx.py dump.asm
python3 asmx.py pagefault.asm
python3 asmx.py hello_task.asm
cp dump.bin dir/dump.bin
cp pagefault.bin dir/pagefault.bin
cp hello_task.bin dir/hello_task.bin
```

## Run

```sh
python3 emu.py
```

Simple OS 起動後、次のコマンドで確認します。

```text
> exec dump.bin
> taskexec hello_task.bin
> exec pagefault.bin
```

## Related Article

- [「いちばんやさしい！OS自作超入門」第7章で仮想メモリとページフォルトを確認する](https://pc-fan.net/os-book-code-chapter7-virtual-memory/)
