#ifndef ASYNCC_H
#define ASYNCC_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __has_attribute
#define __has_attribute(x) 0
#endif

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if __has_attribute(warn_unused_result)
#define ETH_RESULT_USE_CHECK __attribute__((warn_unused_result))
#else
#define ETH_RESULT_USE_CHECK
#endif

void NimMain(void);

typedef struct Context Context;

ETH_RESULT_USE_CHECK Context *createAsyncTaskContext();

typedef void (*CallBackProc) (int status, char *res);

void retrievePageC(Context *ctx, char *url, CallBackProc cb);
void nonBusySleep(Context *ctx, int secs, CallBackProc cb);
void freeResponse(char *res);
void freeContext(Context *ctx);
void pollAsyncTaskEngine(Context *ctx);

#ifdef __cplusplus
}
#endif

#endif
