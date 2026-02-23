// This is glue code for async_wasm

import createAsyncCModule from './asyncc_wasm.js';   // emcc output

// ---------------------------------------------------------------------------
// Module bootstrap — runs once at import time
// ---------------------------------------------------------------------------

const _mod = await createAsyncCModule();
_mod._asyncc_init();

// ---------------------------------------------------------------------------
// Internal helper — create a one-shot C callback that resolves/rejects a
// Promise, then removes itself from the WASM function table.
//
// The signature 'vii' means: void return, two i32 arguments.
// This matches CallBackProc = (int status, char *res).
// ---------------------------------------------------------------------------

function _makeCallback(resolve, reject) {
    const fp = _mod.addFunction((status, resPtr) => {
        const body = _mod.UTF8ToString(resPtr);
        _mod._asyncc_free_response(resPtr);   // free Nim-allocated string
        _mod.removeFunction(fp);              // release the table slot

        if (status === 0) {
            resolve(body);
        } else {
            const err = new Error(body);
            err.status = status;
            reject(err);
        }
    }, 'vii');
    return fp;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Fetch a URL.
 * @param   {string}          url
 * @returns {Promise<string>} resolved with the response body on success,
 *                            rejected with an Error (err.status = -1 | -2)
 *                            on failure or cancellation.
 */
export function fetch(url) {
    return new Promise((resolve, reject) => {
        const cb = _makeCallback(resolve, reject);
        _mod.ccall('asyncc_fetch', null, ['string', 'number'], [url, cb]);
    });
}

/**
 * Non-blocking sleep.
 * @param   {number}          seconds
 * @returns {Promise<string>} resolves with "slept" after the delay.
 */
export function sleep(seconds) {
    return new Promise((resolve, reject) => {
        const cb = _makeCallback(resolve, reject);
        _mod.ccall('asyncc_sleep', null, ['number', 'number'], [seconds, cb]);
    });
}

/**
 * Cancel the poll loop and free the Nim async context.
 * After calling this, fetch/sleep will silently no-op.
 */
export function shutdown() {
    _mod._asyncc_shutdown();
}
