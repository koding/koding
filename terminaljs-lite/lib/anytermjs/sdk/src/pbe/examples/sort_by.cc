#include "sort_by.hh"

#include <vector>

using namespace std;
using namespace pbe;


struct A {
  int x;
  int y;
  bool z;
  A(int x_, int y_, bool z_): x(x_), y(y_), z(z_) {}
};


int main()
{
  std::vector<A> v;
  v.push_back(A(1,2,true));
  v.push_back(A(3,4,false));
  v.push_back(A(9,0,true));

  sort_by(v.begin(),v.end(),&A::y);
}

