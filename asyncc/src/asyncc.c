#include "./asyncc.h"
#include <stdio.h>
#include <unistd.h>


void callme(Response *res) {
  printf("Request finished successfully\n");
  printResponse(res);
}

int main() {
  NimMain();
  Response *res = createResponse(); 
  retrievePageC(res, "https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md");
  printf("Waiting for fetch\n");
  dispatchLoop(res, callme);
  freeResponse(res);
}
