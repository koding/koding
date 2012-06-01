// include/ffs.hh
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

#ifndef pbe_ffs_hh
#define pbe_ffs_hh

// ffs - Find First Set
// This is overloading of the libc ffs* functions for different int types.
// Find the least significant bit set in a value and return its index.
// Bits are numbered starting from 1.
// If no bits are set, return 0.

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#include <string.h>
#undef _GNU_SOURCE
#else
#include <string.h>
#endif

#include <boost/cstdint.hpp>


namespace pbe {

inline int ffs(::uint32_t i) {
  return ::ffsl(i);
}

inline int ffs(::int32_t i) {
  return ::ffsl(i);
}

inline int ffs(::uint64_t i) {
  return ::ffsll(i);
}

inline int ffs(::int64_t i) {
  return ::ffsll(i);
}

};


#endif

