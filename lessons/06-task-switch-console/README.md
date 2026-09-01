# Chapter 6

「いちばんやさしい！OS自作超入門」第6章の学習用コードです。

第6章では、タイマー割り込みを使ったタスク切り替えを拡張し、タスク1からタスク3までをタスク0と並行して動かします。あわせて、仮想コンソールの切り替えも確認します。

## Files

- `os.asm`: 第6章のOSコード
- `os.bin`: `os.asm` をアセンブルしたOSイメージ
- `emu.py`: 第6章用のCPUエミュレータ
- `asm.py`: 書籍付属のアセンブラ
- `asmx.py`: エラー表示を補助したアセンブラ
- `sleep.asm`: `sleep` システム関数の確認用プログラム
- `pi.asm`: `exec` コマンドの確認用プログラム
- `dir/`: Simple OS の `exec` から読む `.bin` ファイル

## Build

```sh
python3 asmx.py os.asm
python3 asmx.py sleep.asm
cp sleep.bin dir/sleep.bin
```

`asm.py` を使う場合も同じです。

```sh
python3 asm.py os.asm
python3 asm.py sleep.asm
cp sleep.bin dir/sleep.bin
```

## Run

```sh
python3 emu.py
```

Simple OS 起動後、仮想コンソールを切り替えて、タスク1からタスク3のメッセージを確認します。

```text
Ctrl+] に続いて 1
Ctrl+] に続いて 2
Ctrl+] に続いて 3
```

`exec` から `sleep.bin` を実行する場合は、プロンプトで次を入力します。

```text
> exec sleep.bin
```

## Notes

- 図11の `_task_switch:` は、既存の `_task_switch:` 以降を置き換えるコードとして扱います。
- 古い `_task_switch:`、`_select_next:`、`_int_timer_end:`、`int_other:` を残すと、同名ラベルが複数定義されます。
- タスク切り替えでは、初期スタックに積む値と `_int_timer_end:` で復元する値の数を合わせます。
