// include/create_dir.hh
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


#ifndef libpbe_create_dir_hh
#define libpbe_create_dir_hh

#include "Exception.hh"

#include <sys/stat.h>
#include <sys/types.h>

#include <string>

namespace pbe {


// Simple wrapper for mkdir().  Doesn't create parent directories; fails
// if the directory already exists or is a file.

inline void create_dir(std::string path, mode_t mode = 0777) {
  int r = ::mkdir(path.c_str(),mode);
  if (r==-1) {
    pbe::throw_ErrnoException("mkdir()");
  }
}


// Check for and create necessary parent directories.  Succeeds if the
// directory already exists; fails if it is a file.

extern void create_dir_with_parents(const std::string path, mode_t mode = 0777);


};

#endif

