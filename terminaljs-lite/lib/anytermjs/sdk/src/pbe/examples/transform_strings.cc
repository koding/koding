// examples/transform_strings.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004 Philip Endecott

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
// Example for use of StringTransformer class

// Create a string transformer object to transform strings.
// Create the object once (a bit expensive) and use it many time (cheapish)
// For example: transform a string to escape quotes, make upper case etc.


#include "StringTransformer.hh"

#include <iostream>
#include <sstream>
using namespace std;


bool is_ctrl(char c) {
  return c<32;
}

string to_escseq(char c) {
  ostringstream s;
  s << '\\' << static_cast<int>(c);
  return s.str();
}


int main(int argc, char* argv[])
{
  StringTransformer escape_quotes;
  escape_quotes.add_cs_rule('\"', "\\\"");  // replace " with \"

  StringTransformer escape_ctrl;
  escape_ctrl.add_pf_rule(is_ctrl, to_escseq);
  
  while (1) {
    char buf[128];
    cin.getline(buf,sizeof(buf));
    string s(buf);

    cout << "Escape quotes:     " << escape_quotes(s) << endl;
    cout << "Escape ctrls:      " << escape_ctrl(s) << endl;
  }
}
