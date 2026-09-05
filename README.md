# os-book-code-practice

『いちばんやさしい！OS自作超入門』を読み進めながら、各章で試したコード、つまずいた点、確認用の実行手順をまとめる補助リポジトリです。

書籍本文の代替ではなく、ブログ記事と連動して、読者が同じ状態のコードを再現できるようにすることを目的にしています。

このリポジトリでは、ブログ記事から参照しやすいように、章ごとの完成状態を `lessons/` にまとめています。

## Lessons

- `lessons/03-assembly-programs/`: 第3章までの単体プログラムと `early.py` の確認
- `lessons/04-simple-os-commands/`: Simple OS の起動、`exec`、`date` コマンドの確認
- `lessons/05-sleep-task-state/`: `sleep` システム関数とタスク状態の確認
- `lessons/06-task-switch-console/`: タイマー割り込みによるタスク切り替えと仮想コンソールの確認
- `lessons/07-virtual-memory-page-fault/`: 仮想メモリ、ページテーブル、ページフォルトの確認

各ディレクトリの `README.md` に、使うファイルと実行手順をまとめています。

## 動作環境

Python 3.8以降が必要です。macOSまたはLinuxでの実行を想定しています。Windowsの場合はWSL上のLinux環境を使ってください。

外部ライブラリは不要です。

## 初期章の使い方

第3章までの単体プログラムは、`lessons/03-assembly-programs/` で確認します。

```sh
cd lessons/03-assembly-programs
python3 asm.py asm_code/hello.asm
python3 early.py asm_code/hello.bin
```

## 関連記事

- [「いちばんやさしい！OS自作超入門」第3章まででつまずいたこと | UNIX Cafe](https://pc-fan.net/os-book-code-chapter3-notes/)
- [「いちばんやさしい！OS自作超入門」第4章でつまずいたこと | UNIX Cafe](https://pc-fan.net/os-book-code-chapter4-troubleshooting/)
- [「いちばんやさしい！OS自作超入門」第7章で仮想メモリとページフォルトを確認する | UNIX Cafe](https://pc-fan.net/os-book-code-chapter7-virtual-memory/)
