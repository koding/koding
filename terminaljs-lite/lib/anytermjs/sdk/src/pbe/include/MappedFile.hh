// include/MappedFile.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2007 Philip Endecott

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

#ifndef libpbe_MappedFile_hh
#define libpbe_MappedFile_hh

#include "FileDescriptor.hh"
#include "Exception.hh"

#include <sys/mman.h>


namespace pbe {

class MappedFile {

public:
  const size_t length;
  const off_t offset;
  char* const addr;

  MappedFile(pbe::FileDescriptor& fd, size_t length_, pbe::FileDescriptor::open_mode_t open_mode,
             off_t offset_ = 0, bool copy_on_write = false):
    length(length_), offset(offset_),
    addr(reinterpret_cast<char*>(fd.mmap(length,open_mode,offset,copy_on_write)))
  {}

  ~MappedFile() {
    int rc = munmap(addr,length);
    if (rc==-1) {
      pbe::throw_ErrnoException("munmap()");
    }
  }

  operator char* () const { return addr; }
  
  template <typename T>
  T* ptr(int offset) const {
    return reinterpret_cast<T*>(reinterpret_cast<char*>(addr)+offset);
  }

  template <typename T>
  T& ref(int offset) const {
    return *ptr<T>(offset);
  }

  void sync() {
    int rc = ::msync(addr,length,MS_SYNC|MS_INVALIDATE);
    if (rc==-1) {
      throw_ErrnoException("msync()");
    }
  }

};

};

#endif
