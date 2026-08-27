# Chapter 4 Files

「いちばんやさしい！OS自作超入門」第4章を試すための補助ファイル一式です。

元リポジトリでは各章の完成状態ごとのファイルが分かれていないため、第4章の記事で使う状態をこのディレクトリにまとめています。

## Files

- `os.asm`
  - 第4章の完成版として使う `os.asm` です。
  - `reg`、`ls`、`exec`、tick カウント、`date` コマンドの追加を含みます。
  - 書籍の図24にある `STDI R8, [basetime]` は、現在のアセンブラに合わせて `STDI R8, basetime` にしています。
  - 図24から図26の範囲では見当たらない `do_date:` 本体も追加しています。

- `asm.py`
  - アセンブラです。

- `asmx.py`
  - `asm.py` のエラー表示を読みやすくした補助版アセンブラです。
  - 未定義ラベル、オペランド不足、不正レジスタなどを `ファイル名:行番号: error: ...` 形式で表示します。

- `emu.py`
  - Simple OS を起動する CPU エミュレータです。
  - この章では `os.bin` を読み込んで起動します。

- `pi.asm`
  - `exec` コマンドの確認用プログラムです。

- `dir/`
  - Simple OS の `exec` コマンドが参照するディレクトリです。
  - `pi.bin` などの実行ファイルをここに置きます。

## Build and Run

このディレクトリで次のように実行します。

```sh
python3 asmx.py os.asm
python3 emu.py
```

`asm.py` を使う場合も同じです。

```sh
python3 asm.py os.asm
python3 emu.py
```

## Check `exec`

`exec` コマンドを確認する場合は、`pi.asm` をアセンブルして `dir/` に置きます。

```sh
python3 asmx.py pi.asm
cp pi.bin dir/pi.bin
python3 emu.py
```

Simple OS が起動したら、プロンプトで次を入力します。

```text
exec pi.bin
```

## Check `date`

Simple OS が起動したら、プロンプトで次を入力します。

```text
date
```

現在時刻が次のような形式で表示されれば成功です。

```text
2026-08-27 17:50:47
```

## Notes

生成済みの `os.bin` や `pi.bin` は含めていません。

読者の環境で `asm.py` または `asmx.py` を使って生成してください。
