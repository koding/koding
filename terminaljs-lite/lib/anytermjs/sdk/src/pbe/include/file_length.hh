// include/file_length.hh
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

#ifndef pbe_file_length_hh
#define pbe_file_length_hh

#include "Exception.hh"

#include <string>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


// Find the length of a file, given its pathname


namespace pbe {

  ::off_t file_length(const char* pathname) {
    struct ::stat s;
    int rc = ::stat(pathname,&s);
    if (rc==-1) {
      throw_ErrnoException("stat()");
    }
    return s.st_size;
  }

  ::off_t file_length(std::string pathname) {
    return file_length(pathname.c_str());
  }

};

#endif

