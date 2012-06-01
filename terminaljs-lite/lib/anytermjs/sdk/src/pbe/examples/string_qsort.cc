#include <string>
#include <vector>
#include <iostream>

#include "string_qsort.hh"

using namespace std;
using namespace pbe;


int main()
{
  typedef vector<string> data_t;
  data_t data;

  while (cin.good()) {
    string s;
    getline(cin,s);
    data.push_back(s);
  }

  string_qsort(data.begin(), data.end());

// Or try this for comparison:
// std::sort(data.begin(), data.end());
// The result should be the same.

  for (data_t::const_iterator i = data.begin();
       i != data.end(); ++i) {
    cout << *i << "\n";
  }
}

