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

ETH_RESULT_USE_CHECK
Response *createResponse();

typedef void (*CallBackProc) (Response *res);

void retrievePageC(Response *res, char *url);
void freeResponse(Response *res);
void dispatchLoop(Response *res, CallBackProc cb);
void printResponse(Response *res);

#endif
