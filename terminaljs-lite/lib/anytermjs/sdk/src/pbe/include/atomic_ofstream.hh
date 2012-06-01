// include/atomic_ofstream.hh
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

#ifndef libpbe_atomic_ofstream_hh
#define libpbe_atomic_ofstream_hh

#include "Exception.hh"

#include <unistd.h>
#include <stdio.h>

#include <fstream>
#include <string>


namespace pbe {


// atomic_ofstream is like std::ofstream except that the stream writes to
// a temporary file.  When the file has been completely written the client
// code should call commit() which removes any existing file and moves the
// new one into its place; this should happen somewhat atomically.  If
// commit() has not been called by the time the destructor is reached
// the temporary file is removed and the original file is left unchanged.


struct atomic_ofstream_base {
  const std::string orig_fn;
  const std::string tmp_fn;
  atomic_ofstream_base(std::string orig_fn_):
    orig_fn(orig_fn_),
    tmp_fn(orig_fn+".tmp")
  {}
};


class atomic_ofstream:
  private atomic_ofstream_base,
  public std::ofstream {

  bool committed;

public:
  atomic_ofstream(std::string orig_fn_):
    atomic_ofstream_base(orig_fn_),
    std::ofstream(tmp_fn.c_str()),
    committed(false)
  {}

  void commit() {
    if (!committed) {
      std::ofstream::close();
      // We don't need to remove the old file; rename() does this.
      int r = ::rename(tmp_fn.c_str(),orig_fn.c_str());
      if (r==-1) {
        throw_ErrnoException("rename()");
      }
      committed = true;
    }
  }

  ~atomic_ofstream() {
    if (!committed) {
      std::ofstream::close();
      ::unlink(tmp_fn.c_str());
    }
  }

};


};


#endif


