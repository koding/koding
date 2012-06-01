// examples/directory_explorer.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2006 Philip Endecott

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


// Demonstrate the libpbe::Directory class and get_filetype.
// Main program takes a directory name and recursively prints the filenames 
// below it.

#include <iostream>

#include "Directory.hh"
#include "FileType.hh"
#include "Exception.hh"


using namespace std;
using namespace libpbe;


void explore(Directory& d)
{
  for (Directory::const_iterator i = d.begin();
       i != d.end(); ++i) {
    cout << i->pathname << "\n";
    if (get_filetype(i->pathname)==directory) {
      Directory subdir(i->pathname);
      explore(subdir);
    }
  }
}


int main(int argc, char* argv[])
{
  try { try {

    if (argc!=2) {
      cerr << "usage:\n"
           << "  directory_recursor <directory name>\n";
      exit(1);
    }

    string dirname = argv[1];
    Directory d(dirname);
    explore(d);

    exit(0);

  } RETHROW_MISC_EXCEPTIONS }
  catch (Exception& E) {
    E.report(cerr);
    exit(1);
  }
}
