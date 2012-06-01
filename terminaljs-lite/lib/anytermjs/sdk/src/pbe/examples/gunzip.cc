// examples/gunzip.cc
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2008 Philip Endecott

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

#include "Gunzipper.hh"

#include "FileDescriptor.hh"

#include <string>
#include <iostream>

using namespace std;
using namespace pbe;


int main(int argc, char* argv[])
{
  if (argc!=2) {
    cerr << "Usage: gunzip <file.gz>\n";
    return 1;
  }

  string fn = argv[1];
  FileDescriptor fd(fn,FileDescriptor::read_only);

  string in = fd.readall();

  Gunzipper gz;

  string out = gz(in);

  cout << out;

  return 0;
}

