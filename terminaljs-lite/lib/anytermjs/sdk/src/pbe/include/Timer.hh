// include/Timer.cc
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


// A Timer.
// Constructor takes a period (a double, in seconds), and the expired() method indicates 
// whether that much time has elapsed since construction.


#ifndef pbe_Timer_hh
#define pbe_Timer_hh

#include "HPtime.hh"


namespace pbe {

class Timer {

private:
  HPtime end_time;

public:
  Timer(double dt):
    end_time(HPtime::now() + dt)
  {}

  bool expired() {
    return end_time<HPtime::now();
  }
};


};


#endif

