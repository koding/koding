#include <iostream>
#include <string>

#include "base64.hh"

using namespace std;
using namespace pbe;


int main()
{
  string s="dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZyEKCg==";
  cout << decode_base64(s);
}

