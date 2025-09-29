#include "./asyncc.h"

int main() {
  NimMain();
  Account *acc = retrievePageC("https://raw.githubusercontent.com/status-im/nim-chronos/master/README.md");
  freeResponse(acc);
}
