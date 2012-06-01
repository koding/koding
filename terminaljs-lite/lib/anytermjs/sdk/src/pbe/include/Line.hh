// include/Line.hh
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

#ifndef libpbe_Line_hh
#define libpbe_Line_hh

#include "Point.hh"
#include "Vector.hh"
#include "Box.hh"


namespace pbe {

template <typename COORD_T>
struct Line {
  typedef COORD_T coord_t;
  typedef Point<coord_t> point_t;

  point_t a;
  point_t b;

  Line() {}

  Line(const Line& other):
    a(other.a), b(other.b)
  {}

  Line(point_t a_, point_t b_):
    a(a_), b(b_)
  {}

  bool operator==(const Line& other) const {
    return (a==other.a && b==other.b);
  }

  bool operator!=(const Line& other) const {
    return ! operator==(other);
  }
};



template <typename COORD_T>
bool line_crosses_line(Line<COORD_T> u, Line<COORD_T> v, Point<COORD_T>& cross)
{
  // Do lines u and v cross?  If so, find the point where they cross.
  // Precondition: the lines must not be points.
  //
  // Method:
  // U = u.a + alpha(u.b-u.a)
  // V = v.a + beta(v.b-v.a)
  // Solve for U=V
  // If 0<=alpha<=1 und 0<=beta<=1 then the lines cross.
  // 
  // u.x = u.a.x + alpha(u.b.x-u.a.x)
  // u.y = u.a.y + alpha(u.b.y-u.a.y)
  // v.x = v.a.x + beta(v.b.x-v.a.x)
  // v.y = v.a.y + beta(v.b.y-v.a.y)
  //
  // u.a.x + alpha(u.b.x-u.a.x) = v.a.x + beta(v.b.x-v.a.x)
  // u.a.y + alpha(u.b.y-u.a.y) = v.a.y + beta(v.b.y-v.a.y)
  //
  // alpha = ( v.a.x + beta(v.b.x-v.a.x) - u.a.x ) / (u.b.x-u.a.x)     provided u.b.x!=u.a.x
  // alpha = ( v.a.y + beta(v.b.y-v.a.y) - u.a.y ) / (u.b.y-u.a.y)     provided u.b.y!=u.a.y
  // ( v.a.x + beta(v.b.x-v.a.x) - u.a.x ) / (u.b.x-u.a.x) = ( v.a.y + beta(v.b.y-v.a.y) - u.a.y ) / (u.b.y-u.a.y)
  // ( v.a.x + beta(v.b.x-v.a.x) - u.a.x ) (u.b.y-u.a.y) = ( v.a.y + beta(v.b.y-v.a.y) - u.a.y ) (u.b.x-u.a.x)
  // beta.(v.b.x-v.a.x).(u.b.y-u.a.y) + (v.a.x-u.a.x).(u.b.y-u.a.y) = beta.(v.b.y-v.a.y).(u.b.x-u.a.x) + (v.a.y-u.a.y).(u.b.x-u.a.x)
  // beta.(v.b.x-v.a.x).(u.b.y-u.a.y) - beta.(v.b.y-v.a.y).(u.b.x-u.a.x) = (v.a.y-u.a.y).(u.b.x-u.a.x) - (v.a.x-u.a.x).(u.b.y-u.a.y)
  // beta = ( (v.a.y-u.a.y).(u.b.x-u.a.x) - (v.a.x-u.a.x).(u.b.y-u.a.y) ) / ( (v.b.x-v.a.x).(u.b.y-u.a.y) - (v.b.y-v.a.y).(u.b.x-u.a.x) )
  //
  // beta = ( u.a.x + alpha(u.b.x-u.a.x) - v.a.x ) / (v.b.x-v.a.x)
  // beta = ( u.a.y + alpha(u.b.y-u.a.y) - v.a.y ) / (v.b.y-v.a.y)
  // ( u.a.x + alpha(u.b.x-u.a.x) - v.a.x ) / (v.b.x-v.a.x) = ( u.a.y + alpha(u.b.y-u.a.y) - v.a.y ) / (v.b.y-v.a.y)
  // ( u.a.x + alpha(u.b.x-u.a.x) - v.a.x ) (v.b.y-v.a.y) = ( u.a.y + alpha(u.b.y-u.a.y) - v.a.y ) (v.b.x-v.a.x)
  // alpha.(u.b.x-u.a.x).(v.b.y-v.a.y) + (u.a.x-v.a.x).(v.b.y-v.a.y) = alpha.(u.b.y-u.a.y).(v.b.x-v.a.x) + (u.a.y-v.a.y).(v.b.x-v.a.x)
  // alpha.(u.b.x-u.a.x).(v.b.y-v.a.y) - alpha.(u.b.y-u.a.y).(v.b.x-v.a.x) = (u.a.y-v.a.y).(v.b.x-v.a.x) - (u.a.x-v.a.x).(v.b.y-v.a.y)
  // alpha = ( (u.a.y-v.a.y).(v.b.x-v.a.x) - (u.a.x-v.a.x).(v.b.y-v.a.y) ) / ( (u.b.x-u.a.x).(v.b.y-v.a.y) - (u.b.y-u.a.y).(v.b.x-v.a.x) )
  //
  // Note that the denominators of the expressions for alpha and beta are almost the
  // same, differing only in sign.
  // If this expression is zero it indicates that that lines do not cross because they
  // are parallel, or that they are co-linear.

  double alpha_denom = (u.b.x-u.a.x)*(v.b.y-v.a.y) - (u.b.y-u.a.y)*(v.b.x-v.a.x);
  if (alpha_denom==0) {
    // In the case of co-linear lines, do we consider them to cross if they overlap?
    // It's simplest to say "no", and always return false here.
    return false;

  } else {
    double alpha_num = (u.a.y-v.a.y)*(v.b.x-v.a.x) - (u.a.x-v.a.x)*(v.b.y-v.a.y);
    double alpha = alpha_num / alpha_denom;
    if (alpha<0 || alpha>1) {
      return false;
    }
    double beta_denom = -alpha_denom;
    double beta_num = (v.a.y-u.a.y)*(u.b.x-u.a.x) - (v.a.x-u.a.x)*(u.b.y-u.a.y);
    double beta = beta_num / beta_denom;
    if (beta<0 || beta>1) {
      return false;
    }
    Vector<COORD_T> uvec = u.b-u.a;
    cross = u.a + uvec * alpha;
    return true;
  }
}


template <typename COORD_T>
bool line_crosses_box(Box<COORD_T> b, Line<COORD_T>& l)
{
  // Does box b contain any part of line l?
  // If line l crosses the boundary of the box, it is modified in place to
  // clip at the boundary.

  if (b.contains(l.a) && b.contains(l.b)) {
    // Both ends inside the box - easy.
    return true;
  }

  if (   (l.a.x < b.x0 && l.b.x < b.x0)
      || (l.a.x > b.x1 && l.b.x > b.x1)
      || (l.a.y < b.y0 && l.b.y < b.y0)
      || (l.a.y > b.y1 && l.b.y > b.y1) ) {
    // Line can't cross the box - easy.
    return false;
  }

  // There's a chance that the line crosses the box, but at least one
  // end is outside it and will need to be clipped.
  Point<COORD_T> cross;

  bool crosses_left = line_crosses_line(l,Line<COORD_T>(b.x0y0(),b.x0y1()),cross);
  if (crosses_left) {
    if (l.a.x<=b.x0) {
      l.a = cross;
    } else {
      l.b = cross;
    }
  }

  bool crosses_top = line_crosses_line(l,Line<COORD_T>(b.x0y1(),b.x1y1()),cross);
  if (crosses_top) {
    if (l.a.y>=b.y1) {
      l.a = cross;
    } else {
      l.b = cross;
    }
  }

  bool crosses_right = line_crosses_line(l,Line<COORD_T>(b.x1y1(),b.x1y0()),cross);
  if (crosses_right) {
    if (l.a.x>=b.x1) {
      l.a = cross;
    } else {
      l.b = cross;
    }
  }

  bool crosses_bottom = line_crosses_line(l,Line<COORD_T>(b.x1y0(),b.x0y0()),cross);
  if (crosses_bottom) {
    if (l.a.y<=b.y0) {
      l.a = cross;
    } else {
      l.b = cross;
    }
  }

  return crosses_left || crosses_top || crosses_right || crosses_bottom;
}


};


#endif

