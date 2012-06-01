// include/ReadTiffFile.hh
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

#ifndef libpbe_ReadTiffFile_hh
#define libpbe_ReadTiffFile_hh

#include <tiffio.h>

#include <boost/noncopyable.hpp>

#include <stdint.h>


// ReadTiffFile is a wrapper around libtiff's facilities for reading
// a TIFF file.  The ctor takes a filename; you can then access properties
// such as the dimensions of the image.
//
// libtiff provides various methods to access the pixel data, some of
// which work with all files and others work with files with particular
// organisations [tiff allows data to be in raster order or tiled, with
// the colour channels packed or separate, etc].  This wrapper currently
// only supports reading in "ARGB strips", i.e. the colours are decoded
// to 32-bits-per-pixel and the data is in strips the full width of the
// image and some some number of pixels (possibly 1) high.
//
// Boost.GIL also has a libtiff wrapper, but I believe that it only
// supports reading whole images.


namespace pbe {


struct ReadTiffFile: boost::noncopyable {
  TIFF* const tiff;
  ReadTiffFile(const char* fn):
    tiff(TIFFOpen(fn,"r"))
  {
    if (!tiff) {
      throw "TIFFOpen() failed";
    }
  }
  ~ReadTiffFile() {
    TIFFClose(tiff);
  }

  uint32_t width() const {
    uint32_t w;
    int r = TIFFGetField(tiff,TIFFTAG_IMAGEWIDTH,&w);
    if (r==0) {
      throw "TIFFGetField(TIFFTAG_IMAGEWIDTH); failed";
    }
    return w;
  }
  uint32_t height() const {
    uint32_t h;
    int r = TIFFGetField(tiff,TIFFTAG_IMAGELENGTH,&h);
    if (r==0) {
      throw "TIFFGetField(TIFFTAG_IMAGLENGTH); failed";
    }
    return h;
  }
  uint32_t rows_per_strip() const {
    uint32_t n;
    int r = TIFFGetField(tiff,TIFFTAG_ROWSPERSTRIP,&n);
    if (r==0) {
      throw "TIFFGetField(TIFFTAG_ROWSPERSTRIP); failed";
    }
    return n;
  }
  size_t number_of_strips() const {
    return TIFFNumberOfStrips(tiff);
  }

  void read_rgba_strip(uint32_t row, uint32_t* data) const {
    int r = TIFFReadRGBAStrip(tiff,row,data);
    if (r==0) {
      throw "TIFFReadRGBAStrip failed";
    }
  }
};


};


#endif

