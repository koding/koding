#include <iostream>

#include "fixed.hh"
#include "safe_int.hh"

using namespace std;
using namespace pbe;

typedef pbe::fixed<16,8> f1;
typedef pbe::fixed<16,10> f2;

int main(int argc, char* argv[])
{
  f1 a;
  f2 b;
  f1 c;
  f2 d;
  pbe::fixed<24,26> e;

  a = 0.25;
  b = 128;

  c = a+b;
  d = c * a;
  e = d / a;

  cout << "a=" << static_cast<double>(a) << " (a.val = " << a.val << ")\n";
  cout << "b=" << static_cast<double>(b) << " (b.val = " << b.val << ")\n";
  cout << "c=" << static_cast<double>(c) << " (c.val = " << c.val << ")\n";
  cout << "d=" << static_cast<double>(d) << " (d.val = " << d.val << ")\n";
  cout << "e=" << static_cast<double>(e) << " (e.val = " << e.val << ")\n";

  typedef pbe::fixed<8,5,pbe::safe_int<13> > f_t;
  f_t f;
  f = a;

  while (1) {
    f = f+f;
    cout << "f=" << static_cast<double>(f) << "\n";
  }
}

