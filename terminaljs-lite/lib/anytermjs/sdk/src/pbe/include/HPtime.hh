// include/HPtime.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2007-2008 Philip Endecott

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


// High-precision time.
// Convertible to/from a double, representing the time in seconds since the epoch.
// Resolution is whatever gettimeofday provides, which is at best microseconds.


#ifndef pbe_HPtime_hh
#define pbe_HPtime_hh

#include <sys/time.h>
#include <time.h>


namespace pbe {

class HPtime {

private:
  double dt;

public:
  HPtime(): dt(0) {}

  HPtime(const HPtime& t): dt(t.dt) {}

  HPtime(double t): dt(t) {}

  operator double() const { return dt; }

  static HPtime now() {
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return HPtime(tv.tv_sec + tv.tv_usec/1e6);
  }

};


};


#endif

