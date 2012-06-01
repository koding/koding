// include/Point.hh
// This file is part of libpbe
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

#ifndef pbe_Point_hh
#define pbe_Point_hh

namespace pbe {


template<typename COORD_T>
struct Point {
  typedef COORD_T coord_t;

  coord_t x;
  coord_t y;

  Point() {}

  Point(const Point<coord_t>& other):
    x(other.x), y(other.y)
  {}

  Point(coord_t x_, coord_t y_):
    x(x_), y(y_)
  {}

  bool operator<(const Point& other) const {
    if (x<other.x) {
      return true;
    } else if (other.x<x) {
      return false;
    } else {
      return y<other.y;
    }
  }

  bool operator==(const Point& other) const {
    return (x==other.x && y==other.y);
  }

  bool operator!=(const Point& other) const {
    return ! operator==(other);
  }

};


};


#endif

