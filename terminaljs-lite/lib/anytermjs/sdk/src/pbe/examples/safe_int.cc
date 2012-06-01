#include <iostream>

#include "safe_int.hh"

#include "Exception.hh"


using namespace std;
using namespace pbe;

typedef safe_int<7> safe_byte;

int main(int argc, char* argv[])
{
  try { try {

    safe_byte a = 1;

    for (int i=0; i<1024; ++i) {
      cout << "a = " << a << "\n";
      a = a * static_cast<safe_byte>(3);
    }

    return 0;

  } RETHROW_MISC_EXCEPTIONS }
  catch (Exception& E) {
    E.report(cerr);
  }
}

