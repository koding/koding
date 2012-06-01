// include/WritePngFile.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
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

#ifndef libpbe_WritePngFile_hh
#define libpbe_WritePngFile_hh

#include <png.h>

#include <boost/noncopyable.hpp>


// WritePngFile is a wrapper around libpng's facilities for writing
// a PNG file.  The ctor takes a filename, image dimensions and so on;
// you then supply pixel data row-at-a-time.  This is a small subsit
// of libpng's facilities.
//
// Boost.GIL also has a libpng wrapper, but I believe that it only
// supports writing whole images.


namespace pbe {


struct WritePngFile {

  FILE* f;
  png_structp png_p;
  png_infop info_p;

  static FILE* check_fopen(const char* fn, const char* mode) {
    FILE* f = fopen(fn,mode);
    if (!f) {
      throw "fopen() failed";
    }
    return f;
  }

  static png_structp check_png_create_write_struct(png_const_charp user_png_ver, png_voidp error_ptr,
                                                   png_error_ptr error_fn, png_error_ptr warn_fn) {
    png_structp p = png_create_write_struct(user_png_ver, error_ptr, error_fn, warn_fn);
    if (!p) {
      throw "png_create_write_struct() failed";
    }
    return p;
  }

  static png_infop check_png_create_info_struct(png_structp png_ptr) {
    png_infop i = png_create_info_struct(png_ptr);
    if (!i) {
      throw "png_create_info_struct() failed";
    }
    return i;
  }

  static void error_fn(png_structp, png_const_charp error_msg) {
    throw error_msg;
  }

  WritePngFile(const char* fn, uint32_t width, uint32_t height,
               int bit_depth=8, int colour_type=PNG_COLOR_TYPE_RGB_ALPHA):
    f(check_fopen(fn,"wb")),
    png_p(check_png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, &error_fn, 0)),
    info_p(check_png_create_info_struct(png_p))
  {
    png_init_io(png_p,f);
    png_set_IHDR(png_p, info_p, width, height, bit_depth, colour_type,
                 PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    png_write_info(png_p, info_p);
  }

  ~WritePngFile() {
    png_write_end(png_p, info_p);
    png_destroy_write_struct(&png_p,&info_p);  // frees both
    fclose(f);
  }

  void write_row(const uint32_t* data) {
    png_write_row(png_p, const_cast<png_byte*>(reinterpret_cast<const png_byte*>(data)));
  }

};


};


#endif

