# os-book-code-practice

書籍「いちばんやさしい！OS自作超入門」（末安 泰三 著、日経BP 刊）を読みながら作成した学習用コードと補助ツールを置くリポジトリです。

このリポジトリでは、ブログ記事から参照しやすいように、章ごとの完成状態を `lessons/` にまとめています。

## Lessons

- `lessons/04-simple-os-commands/`: Simple OS の起動、`exec`、`date` コマンドの確認
- `lessons/05-sleep-task-state/`: `sleep` システム関数とタスク状態の確認
- `lessons/06-task-switch-console/`: タイマー割り込みによるタスク切り替えと仮想コンソールの確認
- `lessons/07-virtual-memory-page-fault/`: 仮想メモリ、ページテーブル、ページフォルトの確認

各ディレクトリの `README.md` に、使うファイルと実行手順をまとめています。

## 初期章用の補助ファイル

第3章までの単体プログラム確認用に、次のファイルも置いています。

| ファイル | 役割 |
| --- | --- |
| `asm.py` | `.asm` を `.bin` に変換するアセンブラ |
| `early.py` | `.bin` をアドレス0から直接実行する初期章用CPUエミュレータ |
| `asm_code/hello.asm` | `Hello, World!` を表示するサンプル |
| `asm_code/mul.asm` | 掛け算と数値表示のサンプル |
| `asm_code/pi.asm` | 円周率計算のサンプル |

## 動作環境

Python 3.8以降が必要です。macOSまたはLinuxでの実行を想定しています。Windowsの場合はWSL上のLinux環境を使ってください。

外部ライブラリは不要です。

## 初期章の使い方

`hello.asm` をアセンブルして、`early.py` で直接実行します。

```sh
python3 asm.py asm_code/hello.asm
python3 early.py asm_code/hello.bin
```

## 関連記事

- [「いちばんやさしい！OS自作超入門」第3章まででつまずいたこと | UNIX Cafe](https://pc-fan.net/os-book-code-chapter3-notes/)
- [「いちばんやさしい！OS自作超入門」第4章でつまずいたこと | UNIX Cafe](https://pc-fan.net/os-book-code-chapter4-notes/)
