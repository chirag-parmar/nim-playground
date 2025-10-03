#include "./asyncc.h"
#include <stdio.h>
#include <unistd.h>


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

void doMultipleAsyncTasks(EngineContext *ctx) {
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme1);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/chronos.nimble", callme2);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/config.nims", callme3);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/nim.cfg", callme4);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme5);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme6);
  nonBusySleep(2);
}

int main() {
  NimMain();
  EngineContext *ctx = createContext(); 
  while(true) {
    doMultipleAsyncTasks(ctx);
    waitForEngine(ctx);
  }
  freeContext(ctx);
}
