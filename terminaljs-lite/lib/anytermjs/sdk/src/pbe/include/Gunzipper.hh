// include/Gunzipper.hh
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

#ifndef pbe_Gunzipper_hh
#define pbe_Gunzipper_hh

#include <zlib.h>

#include <string>


namespace pbe {


class Gunzipper {

  z_stream_s gz;

public:

  Gunzipper() {
    gz.zalloc = Z_NULL;
    gz.zfree = Z_NULL;
    gz.opaque = Z_NULL;
    gz.next_in = Z_NULL;
    gz.avail_in = 0;
    int r = inflateInit2(&gz, 15+32);  // 15 = windowbits; this is the default;
                                       // adding 32 (ARGH!) magically makes it
                                       // recognise both zlib and gzip formats
                                       // (you didn't even know they differed, right?)
    switch (r) {
      case Z_MEM_ERROR:     throw std::bad_alloc();
      case Z_VERSION_ERROR: throw "Z_VERSION_ERROR";
    }
  }

  ~Gunzipper() {
    inflateEnd(&gz);
  }

  struct InvalidData {};

  std::string operator()(const char* in, size_t in_bytes) {
    gz.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(in));
    gz.avail_in = in_bytes;
    std::string out;
    while (gz.avail_in>0 || gz.avail_out==0) {
      char buffer[4096];
      gz.next_out = reinterpret_cast<Bytef*>(buffer);
      gz.avail_out = sizeof(buffer);
      int r = inflate(&gz,Z_SYNC_FLUSH);
      switch (r) {
        case Z_NEED_DICT:    throw "Z_NEED_DICT";
        case Z_DATA_ERROR:   throw InvalidData();
        case Z_STREAM_ERROR: throw InvalidData();
        case Z_MEM_ERROR:    throw std::bad_alloc();
      }
      out.append(buffer,sizeof(buffer)-gz.avail_out);
      if (r==Z_STREAM_END) {
        break;
      }
    }
    return out;
  }

  std::string operator()(std::string in) {
    return operator()(in.data(),in.length());
  }
};



};


#endif

