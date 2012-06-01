// src/create_dir.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe
// (C) 2009 Philip Endecott

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


// Create directories.


#include "create_dir.hh"

#include "FileType.hh"

#include <algorithm>

using namespace std;

namespace pbe {

// Check for and create necessary parent directories.  Succeeds if the
// directory already exists; fails if it is a file.

void create_dir_with_parents(const string path, mode_t mode)
{
  string::const_iterator i = path.begin();
  while (1) {
    string::const_iterator j = find(i,path.end(),'/');
    string elem(i,j);
    string to_here(path.begin(),j);
    if (elem=="" || elem==".") {
    } else {
      switch (get_link_filetype(to_here,true)) {
        case does_not_exist:
          create_dir(to_here,mode);
          break;
        case directory:
          break;
        default:
          throw_ErrnoException("create_dir_with_parents()",EEXIST);
          break;
      }
    }

    if (j==path.end()) {
      break;
    }
  
    i = j;
    ++i;
  }
}


};

