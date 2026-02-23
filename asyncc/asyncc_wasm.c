#include <emscripten.h>
#include "./src/asyncc.h"

static Context *ctx = NULL;

// One tick of the Nim/Chronos event loop.
// Registered with emscripten_set_main_loop so it is called every animation frame
// instead of spinning in a while(true) loop.
static void poll_step(void) {
    pollAsyncTaskEngine(ctx);
}

// Initialize the Nim runtime, create the async context, and hand control of
// the poll loop to the browser's animation frame scheduler.
// Called automatically by asyncc_wasm_glue.js on module load.
EMSCRIPTEN_KEEPALIVE
void asyncc_init(void) {
    NimMain();
    ctx = createAsyncTaskContext();
    // fps=0  → browser controls cadence via requestAnimationFrame
    // sim_inf_loop=0 → return immediately; loop runs asynchronously
    emscripten_set_main_loop(poll_step, 0, 0);
}

// Fetch a URL asynchronously.
// cb is a C function pointer created on the JS side via Module.addFunction().
// It will be called as cb(status, resPtr) when the task completes.
EMSCRIPTEN_KEEPALIVE
void asyncc_fetch(const char *url, CallBackProc cb) {
    if (ctx == NULL) return;
    retrievePageC(ctx, (char *)url, cb);
}

// Sleep for `secs` seconds without blocking the event loop.
// cb is a C function pointer created on the JS side via Module.addFunction().
EMSCRIPTEN_KEEPALIVE
void asyncc_sleep(int secs, CallBackProc cb) {
    if (ctx == NULL) return;
    nonBusySleep(ctx, secs, cb);
}

// Frees the response string allocated by Nim (via allocShared).
// JS must call this after reading the string from a callback's resPtr.
// EMSCRIPTEN_KEEPALIVE prevents dead-code elimination since freeResponse
// is no longer referenced from any C code in this file.
EMSCRIPTEN_KEEPALIVE
void asyncc_free_response(char *res) {
    freeResponse(res);
}

// Tear down the async context and cancel the main loop.
EMSCRIPTEN_KEEPALIVE
void asyncc_shutdown(void) {
    if (ctx == NULL) return;
    emscripten_cancel_main_loop();
    freeContext(ctx);
    ctx = NULL;
}
