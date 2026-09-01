# Chapter 3

「いちばんやさしい！OS自作超入門」第3章までの単体プログラム確認用コードです。

この段階では Simple OS を起動せず、アセンブルした `.bin` を `early.py` で直接実行します。

## Files

- `asm.py`: `.asm` を `.bin` に変換するアセンブラ
- `early.py`: `.bin` をアドレス0から直接実行する初期章用CPUエミュレータ
- `asm_code/hello.asm`: `Hello, World!` を表示するサンプル
- `asm_code/mul.asm`: 掛け算と数値表示のサンプル
- `asm_code/pi.asm`: 円周率計算のサンプル

## Build And Run

```sh
python3 asm.py asm_code/hello.asm
python3 early.py asm_code/hello.bin
```

`mul.asm` も同じ流れで確認できます。

```sh
python3 asm.py asm_code/mul.asm
python3 early.py asm_code/mul.bin
```

`pi.asm` は出力が長くなります。

```sh
python3 asm.py asm_code/pi.asm
python3 early.py asm_code/pi.bin
```
