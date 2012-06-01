// include/Box.hh
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

#ifndef pbe_Box_hh
#define pbe_Box_hh

#include "Point.hh"

#include <algorithm>


namespace pbe {

template<typename COORD_T,
         typename AREA_T = COORD_T>
struct Box {
  typedef COORD_T coord_t;
  typedef AREA_T area_t;
  typedef typename pbe::Point<coord_t> point_t;

  coord_t x0;
  coord_t y0;
  coord_t x1;
  coord_t y1;

  Box() {}

  Box(const Box<coord_t>& other):
    x0(other.x0), y0(other.y0), x1(other.x1), y1(other.y1)
  {}

  Box(coord_t x0_, coord_t y0_, coord_t x1_, coord_t y1_):
    x0(x0_), y0(y0_), x1(x1_), y1(y1_)
  {}

  Box(point_t x0y0, point_t x1y1):
    x0(x0y0.x), y0(x0y0.y), x1(x1y1.x), y1(x1y1.y)
  {}

  Box(point_t x0y0, coord_t w, coord_t h):
    x0(x0y0.x), y0(x0y0.y), x1(x0y0.x+w), y1(x0y0.y+h)
  {}

  coord_t width()  const { return x1-x0; }
  coord_t height() const { return y1-y0; }

  point_t x0y0() const {
    return point_t(x0,y0);
  }

  point_t x0y1() const {
    return point_t(x0,y1);
  }

  point_t x1y0() const {
    return point_t(x1,y0);
  }

  point_t x1y1() const {
    return point_t(x1,y1);
  }

  bool contains(point_t p) const {
    return p.x>=x0 && p.x<x1 && p.y>=y0 && p.y<y1;
  }

  bool contains(Box b) const {
    return contains(b.x0y0()) && contains(b.x1y1());
  }

  void displace(coord_t dx, coord_t dy) {
    x0 += dx;
    x1 += dx;
    y0 += dy;
    y1 += dy;
  }

  bool operator==(const Box& other) const {
    return x0==other.x0 && x1==other.x1 && y0==other.y0 && y1==other.y1;
  }
  
};


template <typename COORD_T>
inline bool overlap(const Box<COORD_T>& lhs, const Box<COORD_T>& rhs) {
  return lhs.x0<=rhs.x1 && lhs.x1>=rhs.x0
      && lhs.y0<=rhs.y1 && lhs.y1>=rhs.y0;
}


template <typename BOX_T>
inline typename BOX_T::area_t area(BOX_T box) {
  return box.width() * box.height();
}


template <typename BOX_T>
inline void expand_box(BOX_T& box, typename BOX_T::point_t point){
  box.x0 = min(box.x0,point.x);
  box.y0 = min(box.y0,point.y);
  box.x1 = max(box.x1,point.x);
  box.y1 = max(box.y1,point.y);
}


template <typename BOX_T>
inline BOX_T intersect(const BOX_T& b1, const BOX_T& b2) {
  return BOX_T( std::max(b1.x0, b2.x0),
                std::max(b1.y0, b2.y0),
                std::min(b1.x1, b2.x1),
                std::min(b1.y1, b2.y1) );
}

};


#endif

