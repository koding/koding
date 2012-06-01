#include <list>
#include <iostream>
#include "sorted_ptr_vector.hh"

using namespace std;
using namespace pbe;


struct A {
  int x;
  int y;
  int z;
  A(int x_, int y_, int z_): x(x_), y(y_), z(z_) {};
};


int main()
{
  list<A*> l;
  l.push_back(new A(1,2,3));
  l.push_back(new A(5,4,3));
  l.push_back(new A(2,3,2));

  typedef sorted_ptr_vector<A, int A::*, &A::z> v_t;
  v_t v(l.begin(),l.end());

  for (v_t::const_iterator i = v.begin(); i != v.end(); ++i) {
    cout << (*i)->x << "," << (*i)->y << "," << (*i)->z << "\n";
  }
}

