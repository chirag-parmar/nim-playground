NIM  ?= nim
GCC  ?= gcc
EMCC ?= emcc
EMAR ?= emar

.PHONY: build build_wasm serve clean

# ── Native ────────────────────────────────────────────────────────────────────

libasyncc.a: src/c_frontend.nim src/asyncc.nim
	$(NIM) c --app:staticlib --noMain:on --header \
	         --out:libasyncc.a src/c_frontend.nim

# Builds libasyncc.a then compiles the native demo binary (see README).
build: libasyncc.a
	$(GCC) -I./src -L. -lasyncc -o asyncc_from_c src/asyncc.c

# ── WASM ─────────────────────────────────────────────────────────────────────
# libasyncc.a contains native objects; emcc needs WASM objects.
# libasyncc_wasm.a is a separate archive compiled by Nim using emcc as the
# C backend so every object file is wasm32 LLVM bitcode.

libasyncc_wasm.a: src/c_frontend.nim src/asyncc.nim
	$(NIM) c --app:staticlib --noMain:on --header \
	         --nimcache:nimcache_wasm \
	         --cc:clang \
	         --clang.exe:$(EMCC) \
	         --clang.linkerexe:$(EMCC) \
	         --cpu:wasm32 --os:linux \
	         --threads:off \
	         -d:emscripten \
	         '--passC:-Wno-error=incompatible-pointer-types' \
	         --out:libasyncc_wasm.a \
	         src/c_frontend.nim
	rm -f libasyncc_wasm.a
	find nimcache_wasm -name '*.o' | xargs $(EMAR) qcs libasyncc_wasm.a

build_wasm: build libasyncc_wasm.a
	$(EMCC) asyncc_wasm.c libasyncc_wasm.a \
	        -I./src \
	        -o asyncc_wasm.js \
	        -s WASM=1 \
	        -s MODULARIZE=1 \
	        -s EXPORT_NAME='createAsyncCModule' \
	        -s EXPORT_ES6=1 \
	        -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","addFunction","removeFunction"]' \
	        -s ALLOW_MEMORY_GROWTH=1 \
	        -s ALLOW_TABLE_GROWTH=1 \
	        -s ENVIRONMENT='web' \
	        -O2

# ── Dev server ───────────────────────────────────────────────────────────────

serve:
	@echo "Open http://localhost:8080/asyncc_wasm_demo.html"
	python3 -m http.server 8080

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean:
	rm -f libasyncc.a libasyncc_wasm.a asyncc_from_c asyncc_wasm.js asyncc_wasm.wasm
	rm -rf nimcache_wasm
