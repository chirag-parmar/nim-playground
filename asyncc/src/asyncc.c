#include "./asyncc.h"
#include <stdio.h>
#include <unistd.h>


void callme1(Response *res) {
  printf("Request 1 finished successfully\n");
  freeResponse(res);
}

void callme2(Response *res) {
  printf("Request 2 finished successfully\n");
  freeResponse(res);
}

void callme3(Response *res) {
  printf("Request 3 finished successfully\n");
  freeResponse(res);
}

void callme4(Response *res) {
  printf("Request 4 finished successfully\n");
  freeResponse(res);
}

void callme5(Response *res) {
  printf("Request 5 finished successfully\n");
  freeResponse(res);
}

void callme6(Response *res) {
  printf("Request 6 finished successfully\n");
  freeResponse(res);
}

int main() {
  NimMain();
  EngineContext *ctx = createContext(); 
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme1);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme2);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme3);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme4);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme5);
  retrievePageC(ctx, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md", callme6);
  printf("Waiting for fetch\n");
  dispatchLoop(ctx);
  freeContext(ctx);
}
