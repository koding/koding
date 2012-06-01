// Get a backtrace when we de-reference a null ponter.

#include <stdlib.h>

#include "segv_backtrace.hh"


int* ptr;

int badstuff(int i)
{
  ptr = NULL;
  return badstuff(*ptr * i);
}


int main()
{
  get_backtrace_on_segv();

  return badstuff(1);
}

