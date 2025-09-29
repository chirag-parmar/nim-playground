### Quick Instructions

```bash
nim c --app:staticlib --noMain:on --header --out:libasyncc.a ./src/c_frontend.nim
gcc -I./src -L. -lasyncc -o asyncc_from_c ./src/asyncc.c
```
