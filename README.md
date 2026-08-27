# os-book-code-practice

書籍「いちばんやさしい！OS自作超入門」（末安 泰三 著、日経BP 刊）を読みながら作成した学習用コードと補助ツールを置くリポジトリです。

現在は、第3章までで登場する `hello.asm`、`mul.asm`、`pi.asm` のような小さな単体プログラムをアセンブルし、CPUエミュレータで直接実行する準備段階のコードを置いています。今後、学習の進行に合わせてOS本体のコードも追加していきます。

## 公開しているファイル

第3章までの段階で必要なファイルは次の通りです。

| ファイル | 役割 |
| --- | --- |
| `asm.py` | `.asm` を `.bin` に変換するアセンブラ |
| `early.py` | `.bin` をアドレス0から直接実行する初期章用CPUエミュレータ |
| `asm_code/hello.asm` | `Hello, World!` を表示するサンプル |
| `asm_code/mul.asm` | 掛け算と数値表示のサンプル |
| `asm_code/pi.asm` | 円周率計算のサンプル |
| `LICENSE` | ライセンス |
| `.gitignore` | 生成物やローカル作業ファイルを除外する設定 |

`.bin` ファイルは生成物です。リポジトリには含めず、手元で `asm.py` を実行して作成します。

## 動作環境

Python 3.8以降が必要です。macOSまたはLinuxでの実行を想定しています。Windowsの場合はWSL上のLinux環境を使ってください。

外部ライブラリは不要です。

## 使い方

`hello.asm` をアセンブルして実行します。

```bash
python3 asm.py asm_code/hello.asm
python3 early.py asm_code/hello.bin
```

実行すると、次のように表示されます。

```text
Hello, World!
CPU halted.
R0: 00000000
...
```

`mul.asm` も同じ流れで実行できます。

```bash
python3 asm.py asm_code/mul.asm
python3 early.py asm_code/mul.bin
```

`pi.asm` は出力が長くなります。

```bash
python3 asm.py asm_code/pi.asm
python3 early.py asm_code/pi.bin
```

## early.pyについて

`early.py` は、書籍序盤の単体プログラムを直接実行するためのCPUエミュレータです。引数で指定した `.bin` をメモリのアドレス0に読み込み、先頭から実行します。

この段階のサンプルは、プログラム末尾の `HALT` でCPUを停止します。OSの `exec` コマンドから呼び出すプログラムで使う `RET` とは実行前提が異なります。

## 関連記事

UNIX Cafeの記事で、第3章まででつまずきやすい点と `early.py` の使い方を整理しています。

- [「いちばんやさしい！OS自作超入門」第3章まででつまずいたこと | UNIX Cafe](https://pc-fan.net/os-book-code-chapter3-notes/)
