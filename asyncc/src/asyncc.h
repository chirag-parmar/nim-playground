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

typedef struct Response Response;
typedef struct EngineContext EngineContext;

ETH_RESULT_USE_CHECK
EngineContext *createContext();

typedef void (*CallBackProc) (Response *res);

void retrievePageC(EngineContext *ctx, char *url, CallBackProc cb);
void freeResponse(Response *res);
void freeContext(EngineContext *ctx);
void dispatchLoop(EngineContext *ctx);
void printResponse(Response *res);

#endif
