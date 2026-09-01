# Chapter 5 Files

「いちばんやさしい！OS自作超入門」第5章を試すための補助ファイル一式です。

第5章の完成状態として、タイマー割り込み、タスク切り替え、`sleep` システム関数、`sleep.bin` 実行確認に必要なファイルをこのディレクトリにまとめています。

## Files

- `os.asm`
  - 第5章の完成版として使う `os.asm` です。
  - タスク0とタスク4の切り替え、`sleep` システム関数、タスク状態とスタックポインタ保存領域を含みます。
  - 書籍および作者リポジトリと同じく、`STDI SP, [_t4_sp]` のような `[label]` 表記を使います。

- `os.bin`
  - `os.asm` から生成した Simple OS のバイナリです。

- `asm.py`
  - アセンブラです。
  - エラー表示を読みやすくした版ですが、`[label]` 表記は受け付けます。

- `asmx.py`
  - `asm.py` の補助版アセンブラです。
  - 未定義ラベル、オペランド不足、不正レジスタなどを `ファイル名:行番号: error: ...` 形式で表示します。

- `emu.py`
  - Simple OS を起動する CPU エミュレータです。
  - この章では `os.bin` を読み込んで起動します。

- `pi.asm`
  - `exec` コマンドの確認用プログラムです。

- `sleep.asm`
  - 第5章の `sleep` システム関数を確認するためのプログラムです。

- `sleep.bin`
  - `sleep.asm` から生成したバイナリです。

- `dir/`
  - Simple OS の `exec` コマンドが参照するディレクトリです。
  - `hello.bin`、`mul.bin`、`pi.bin`、`sleep.bin` を置いています。

## Build

このディレクトリで次のように実行します。

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

Simple OS を起動します。

```sh
python3 emu.py
```

起動後、プロンプトで次を入力します。

```text
exec sleep.bin
```

次のように 1秒、5秒、10秒の待ち時間を挟んで表示されれば成功です。

```text
WAITING 1s
WAITING 5s
WAITING 10s
```

## Notes

- 第5章では、OS側に `sleep` システム関数を追加し、ユーザープログラム側から `CALLI sleep` で呼び出します。
- `sleep` 中はタスク状態を `WAITING` にし、タイマー割り込みで残り tick を減らして、0 になったら `RUNNABLE` に戻します。
- 第5章の `os.asm` は、作者リポジトリと同じ `[label]` 表記に合わせています。
