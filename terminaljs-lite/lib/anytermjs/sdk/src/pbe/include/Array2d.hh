// Array2d.hh
// This file is part of libpbe; see http://anyterm.org/
// (C) 2006 Philip Endecott

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

#ifndef libpbe_Array2d_hh
#define libpbe_Array2d_hh

#include <vector>


namespace pbe {

template <typename T, typename Impl=std::vector<T> >
class Array2d {

public:
  Array2d(unsigned int w, unsigned int h):
    data(w*h), width_(w), height_(h)
  {}

  Array2d(unsigned int w, unsigned int h, T value):
    data(w*h,value), width_(w), height_(h)
  {}

  const T& operator()(unsigned int x, unsigned int y) const {
    return data[y*width_ + x];
  }

  T& operator()(unsigned int x, unsigned int y) {
    return data[y*width_ + x];
  }

  unsigned int width() const { return width_; }
  unsigned int height() const { return height_; }

private:
  Impl data;
  const unsigned int width_;
  const unsigned int height_;
};

};


#endif
