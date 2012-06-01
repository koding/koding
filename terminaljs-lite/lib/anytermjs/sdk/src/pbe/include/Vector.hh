// include/Vector.hh
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

#ifndef pbe_Vector_hh
#define pbe_Vector_hh

#include <cmath>

#include "Point.hh"


namespace pbe {


template<typename COORD_T>
struct Vector {
  typedef COORD_T coord_t;

  coord_t x;
  coord_t y;

  Vector() {}

  Vector(const Vector<coord_t>& other):
    x(other.x), y(other.y)
  {}

  Vector(coord_t x_, coord_t y_):
    x(x_), y(y_)
  {}

  bool operator<(const Vector& other) const {
    if (x<other.x) {
      return true;
    } else if (other.x<x) {
      return false;
    } else {
      return y<other.y;
    }
  }

  float magnitude(void) const {
    float fx = x;
    float fy = y;
    return sqrt(fx*fx + fy*fy);
  }


  Vector operator+=(Vector v) { x += v.x; y += v.y; return *this; }
  Vector operator+ (Vector v) const { Vector r = *this; r += v; return r; }
  Vector operator-=(Vector v) { x -= v.x; y -= v.y; return *this; }
  Vector operator- (Vector v) const { Vector r = *this; r -= v; return r; }

  template <typename DIV_T>
  Vector operator/=(DIV_T divisor) { x /= divisor; y /= divisor; return *this; }

  template <typename DIV_T>
  Vector operator/(DIV_T divisor) const { Vector v = *this; v /= divisor; return v; }

  template <typename MUL_T>
  Vector operator*=(MUL_T multiplier) { x *= multiplier; y *= multiplier; return *this; }

  template <typename MUL_T>
  Vector operator*(MUL_T multiplier) const { Vector v = *this; v *= multiplier; return v; }

};


template <typename COORD_T>
Vector<COORD_T> operator-(const Point<COORD_T>& a, const Point<COORD_T>& b) {
  return Vector<COORD_T>(a.x-b.x, a.y-b.y);
}

template <typename COORD_T>
Point<COORD_T> operator+(const Point<COORD_T>& a, const Vector<COORD_T>& b) {
  return Point<COORD_T>(a.x+b.x, a.y+b.y);
}

template <typename COORD_T>
Point<COORD_T> operator-(const Point<COORD_T>& a, const Vector<COORD_T>& b) {
  return Point<COORD_T>(a.x-b.x, a.y-b.y);
}



};


#endif

