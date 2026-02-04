#include <stdio.h>
#include <unistd.h>

int main() {
  printf("Hello %d!\n", getuid());
  return 0;
}
