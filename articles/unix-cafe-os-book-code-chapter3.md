# 「いちばんやさしい！OS自作超入門」第3章まででつまずいたこと

書籍「いちばんやさしい！OS自作超入門」を読みながら、GitHub で公開されている `os_book_code` を使って第3章まで進めた。

第3章までは、まだ本格的なOS開発というより、アセンブラ、CPUエミュレータ、簡単なアセンブリプログラムを動かすための準備が中心になる。

ただ、書籍本文の手順と現在のGitHub最新版では、いくつか前提が違って見えるところがあった。特に `emu.py` の役割と、`HALT` / `RET` の違いで迷いやすい。

この記事では、第3章まででつまずいた点と、その確認結果をまとめる。

## 使用環境

- macOS
- Python 3
- GitHub リポジトリ: `https://github.com/sueyasu/os_book_code`
- 作業ディレクトリ: `os_book_code`

## 第3章までの位置づけ

第3章までの内容を大きく分けると、次のようになる。

- 第1章: ソースコードを入手してサンプルを動かす
- 第2章: CPUやOSの基本的な考え方を確認する
- 第3章: アセンブリ言語で簡単なプログラムを書く

ここでは、OS本体を作る前に、アセンブリコードをバイナリに変換し、それをCPUエミュレータで実行する流れを確認している。

第4章からは「シングルタスクOSを開発」が始まるので、その前段階として、ここまでの道具の動きを整理しておく。

## `python3.12 -m venv .` の `.` は何を意味するか

書籍の環境構築では、仮想環境を作るコマンドとして次のような形が出てくる。

```sh
python3.12 -m venv .
```

ここで指定している `.` は「現在のディレクトリ」を意味する。

つまり、このコマンドは「現在のディレクトリそのものを仮想環境にする」という指定になる。`.venv/` というディレクトリを作る指定ではない。

実行すると、カレントディレクトリ直下に次のようなファイルやディレクトリが作られる。

```text
bin/
include/
lib/
pyvenv.cfg
```

作業ディレクトリ直下に仮想環境の中身を置きたくない場合は、作成先のディレクトリ名を明示する。

```sh
python3.12 -m venv .venv
source .venv/bin/activate
```

`python -m venv .` の `.` は、`.venv` の省略形ではない。この点は最初に混乱しやすい。

## `Wrote hello.bin (28 bytes)` はエラーではない

書籍では、次のようなコマンドが出てくる。

```sh
python asm.py hello.asm
python emu.py hello.bin
```

1行目を実行すると、次のようなログが表示される。

```text
Wrote hello.bin (28 bytes)
```

これはエラーではない。

`python asm.py hello.asm` は、`hello.asm` を機械語のバイナリに変換するコマンド。この段階では、プログラムはまだ実行されていない。

`Wrote hello.bin (28 bytes)` は、`hello.asm` のアセンブルに成功し、`hello.bin` という28バイトのバイナリを書き出した、という正常な中間ログ。

その次のエミュレータ実行で、初めて `hello.bin` の中身がCPU上で実行される。

## `python emu.py hello.bin` で Simple OS が起動する

現在のGitHub最新版を使っていると、書籍どおりに次を実行しても、期待した `Hello, World!` が表示されないことがある。

```sh
python emu.py hello.bin
```

代わりに、次のような表示になる。

```text
Welcome to Simple OS!
>
```

これは `hello.bin` が実行された結果ではない。

現在のリポジトリ直下にある `emu.py` は、引数で渡した `hello.bin` を読む作りではなく、カレントディレクトリの `os.bin` を読み込んで Simple OS を起動する作りになっている。

そのため、次のように引数を付けても、現在の `emu.py` では引数は使われない。

```sh
python emu.py hello.bin
python emu.py asm_code/hello.bin
python emu.py asm_code/hello.asm
```

どれも実際には `os.bin` の Simple OS が起動する。

## `hello.bin` を直接動かすには `early.py` を使う

書籍序盤の `hello.bin` を単体プログラムとして直接実行したい場合は、初期章用の `early.py` を使う。

```sh
python asm.py hello.asm
python early.py hello.bin
```

この場合は、書籍序盤の説明に近い形で、`hello.bin` が直接CPUエミュレータ上で実行される。

期待する出力は次のような形になる。

```text
Hello, World!
CPU halted.
R0: 00000000
R1: 00000000
R2: 00000000
R3: 00000000
R4: 00000000
R5: 00000000
R6: 00000000
R7: 00000000
R8: 0000000C
R9: 00000000
TP: 00000000
SP: 000FFFFF
PC: 0000000C
PT: 00000000
VT: 00000000
CR: 00000000
```

一方、`python emu.py` で Simple OS が起動している場合、`CPU halted.` とレジスタ一覧は `hello.bin` の実行結果として出ているわけではない。

Simple OS のプロンプトで `exit` を入力したときに、OSが終了して `CPU halted.` が表示される。

```text
Welcome to Simple OS!
> exit
bye.

CPU halted.
...
```

この2つは別の実行経路として分けて考える必要がある。

## `HALT` と `RET` の違い

第3章までのサンプルを動かすうえで、`HALT` と `RET` の違いも重要になる。

簡単に分けると、次のようになる。

- `HALT`: CPUを停止する
- `RET`: 呼び出し元へ戻る

単体プログラムとして直接実行する場合、最後は `HALT` が自然。そこでプログラム全体を終わらせ、CPUを停止する。

一方、Simple OS の `exec` コマンドから外部プログラムとして実行する場合、最後は `RET` が必要になる。`RET` で呼び出し元、つまりOS側のコマンドループへ戻るため。

## `pi.asm` の末尾が書籍とGitHubで違う

円周率を1000桁計算する `pi.asm` で、最後の命令が書籍とGitHub最新版で違っていた。

書籍側では、単体プログラムとして直接実行する流れに見えるため、最後が `HALT` になっている。

一方、GitHub最新版では最後が `RET` になっている。

Git履歴を見ると、次の変更が確認できた。

```diff
-        HALT
+        RET
```

コミットメッセージは次の内容だった。

```text
execコマンドで起動できるように終了方法を変更
```

つまり、GitHub最新版の `pi.asm` は、Simple OS の `exec` コマンドから起動する前提に変更されている。

## `pi.bin` を Simple OS の `exec` から実行する

現在のGitHub最新版の `pi.asm` を使う場合、末尾は `RET` のままでよい。

実行手順は次のようになる。

```sh
cd /path/to/os_book_code

python asm.py os.asm
python asm.py pi.asm

mkdir -p dir
cp pi.bin dir/pi.bin

python emu.py
```

Simple OS が起動したら、プロンプトで次を入力する。

```text
exec pi.bin
```

ここで注意が必要なのは、`exec pi.bin` はリポジトリ直下の `pi.bin` を直接読むわけではない、という点。

`emu.py` の `exec` 処理では、内部的に `dir/<ファイル名>` を開く。そのため、`pi.bin` は事前に `dir/pi.bin` として置いておく必要がある。

`dir/pi.bin` が無い状態で実行すると、次のエラーになる。

```text
File open error.
```

これは `pi.asm` の文法エラーではなく、`exec` が読む場所に `pi.bin` が無いという意味。

## 第3章まででわかったこと

第3章までを現在のGitHub最新版で動かすときは、次の点を押さえておくと混乱しにくい。

- `asm.py` は `.asm` から `.bin` を作る
- `Wrote ...` はアセンブル成功のログ
- 現在の `emu.py` は `os.bin` を起動する
- `python emu.py hello.bin` としても、現在の `emu.py` は `hello.bin` を読まない
- 書籍序盤の単体プログラムを直接実行するなら `early.py` を使う
- `HALT` はCPU停止
- `RET` は呼び出し元へ戻る
- `pi.asm` は単体実行なら `HALT`、Simple OS の `exec` から実行するなら `RET`
- `exec pi.bin` は `dir/pi.bin` を読む

書籍本文とGitHub最新版が、常に同じ段階のコードを前提にしているとは限らない。

迷ったときは、エミュレータが実際にどのファイルを `open()` しているか、`PC` の初期値がどこになっているか、プログラムの最後が `HALT` か `RET` かを見ると切り分けやすい。

## 第4章へ

第4章からは「シングルタスクOSを開発」に入る。

ここからは、`emu.py` が `os.bin` を起動すること自体が本筋になる。第3章までで混乱しやすかった「単体プログラムを直接実行する世界」と「OSを起動して、その上でプログラムを動かす世界」が、ここから少しずつつながっていく。

第4章へ進む前に、次の3つを区別できていればよい。

- `asm.py`: アセンブリをバイナリに変換する
- `early.py`: 書籍序盤の単体プログラムを直接実行する
- `emu.py`: 現在のGitHub最新版では `os.bin` を読み込んで Simple OS を起動する

ここまで整理できたので、次はシングルタスクOSの開発に進む。
