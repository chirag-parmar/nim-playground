#include "./asyncc.h"
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>     // malloc, free
#include <string.h>     // strlen, strcpy
#include <stdbool.h>    // bool type

static bool waitFlag = false;

void callme1(int status, char *res) {
  printf("Request 1 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callme2(int status, char *res) {
  printf("Request 2 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callme3(int status, char *res) {
  printf("Request 3 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callme4(int status, char *res) {
  printf("Request 4 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callme5(int status, char *res) {
  printf("Request 5 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callme6(int status, char *res) {
  printf("Request 6 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void callmevariable(int status, char *res) {
  printf("Request 6 finished successfully\n");
  printf("status: %d\n", status);
  // printf("response: %s\n", res);
  freeResponse(res);
}

void waitFlagIsOver(int status, char *res) {
  printf("waitFlaging finished successfully\n");
  printf("status: %d\n", status);
  
  waitFlag = false;

  // printf("response: %s\n", res);
  freeResponse(res);
}

void testVariableLifecycleC_wrapper(Context *ctx, CallBackProc cb) {
    char *msg = malloc(strlen("hello world!") + 1);
    strcpy(msg, "hello world!");

    bool *flag = malloc(sizeof(bool));
    *flag = true;

    unsigned long long *num = malloc(sizeof(unsigned long long));
    *num = 32ULL;

    testVariableLifecycleC(ctx, msg, *flag, *num, cb);

    free(msg);
    free(flag);
    free(num);
    msg = NULL;
    flag = NULL;
    num = NULL;

    printf("Variables freed!!\n");
}

void doMultipleAsyncTasks(Context *ctx) {
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme1);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/chronos.nimble", callme2);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/config.nims", callme3);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/nim.cfg", callme4);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme5);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme6);
  testVariableLifecycleC_wrapper(ctx, callmevariable);
  nonBusySleep(ctx, 7, waitFlagIsOver); // testVariableLifecycle takes 5 seconds so...
}

int main() {
  NimMain();
  Context *ctx = createAsyncTaskContext(); 
  while(true) {
    if (!waitFlag) {
      waitFlag = true;
      doMultipleAsyncTasks(ctx);
    }
    pollAsyncTaskEngine(ctx);
  }
  freeContext(ctx);
}
