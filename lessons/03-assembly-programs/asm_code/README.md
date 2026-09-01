# asm_code

書籍序盤で動作確認に使う単体アセンブリプログラムです。

各 `.asm` は `asm.py` で `.bin` に変換してから、`early.py` で直接実行します。

```bash
python3 asm.py asm_code/hello.asm
python3 early.py asm_code/hello.bin
```

このディレクトリで生成される `.bin` は Git 管理対象に含めません。
