// src/geometry.cc
// (C) 2008 Philip Endecott
//
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

#include "geometry.hh"

#include <cmath>

using namespace std;


namespace pbe {


float distance(const position& a, const position& b)
{
  return earth_radius * 2.0F * asin(
           sqrt(
             sqr(degsin((a.lat-b.lat)/2.0F))
             + degcos(a.lat)*degcos(b.lat)*sqr(degsin((a.lng-b.lng)/2.0F))
           )
         );
}


float bearing(const position& a, const position& b)
{
  float d = degatan2( degsin(b.lng-a.lng) * degcos(b.lat),
                      degcos(a.lat) * degsin(b.lat)
                      - degsin(a.lat) * degcos(b.lat) * degcos(b.lng-a.lng)
            );
  return normalise_unsigned_angle(d);
}


};
