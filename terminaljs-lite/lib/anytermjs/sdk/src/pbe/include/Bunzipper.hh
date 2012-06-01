// include/Bunzipper.hh
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

#ifndef pbe_Bunzipper_hh
#define pbe_Bunzipper_hh

#ifdef HAVE_BZIP

#include <bzlib.h>

#include <string>


namespace pbe {


class Bunzipper {

  bz_stream bz;

public:

  Bunzipper(bool small_mem = false) {
    bz.bzalloc = NULL;
    bz.bzfree = NULL;
    bz.opaque = NULL;
    int r = BZ2_bzDecompressInit(&bz, 0, small_mem?1:0);
    switch (r) {
      case BZ_CONFIG_ERROR: throw "BZ_CONFIG_ERROR";
      case BZ_PARAM_ERROR:  throw "BZ_PARAM_ERROR";
      case BZ_MEM_ERROR:    throw std::bad_alloc();
    }
  }

  ~Bunzipper() {
    BZ2_bzDecompressEnd(&bz);
  }

  struct InvalidData {};

  std::string operator()(const char* in, size_t in_bytes) {
    bz.next_in = const_cast<char*>(in);
    bz.avail_in = in_bytes;
    std::string out;
    while (bz.avail_in>0) {
      char buffer[4096];
      bz.next_out = buffer;
      bz.avail_out = sizeof(buffer);
      int r = BZ2_bzDecompress(&bz);
      switch (r) {
        case BZ_PARAM_ERROR: throw "BZ_PARAM_ERROR";
        case BZ_DATA_ERROR:  throw InvalidData();
        case BZ_DATA_ERROR_MAGIC: throw InvalidData();
        case BZ_MEM_ERROR: throw std::bad_alloc();
      }
      out.append(buffer,sizeof(buffer)-bz.avail_out);
    }
    return out;
  }

  std::string operator()(std::string in) {
    return operator()(in.data(),in.length());
  }
};



};


#endif

#endif

