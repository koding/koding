// include/sleep.hh
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

#ifndef libpbe_sleep_hh
#define libpbe_sleep_hh

#include <time.h>

#include <cmath>

#include "Exception.hh"


namespace pbe {

inline void sleep(double t)
{
  double whole_secs;
  double frac_secs = modf(t, &whole_secs);
  struct timespec ts;
  ts.tv_sec  = static_cast<int>(whole_secs);
  ts.tv_nsec = static_cast<int>(frac_secs*1e9);
  struct timespec rem;
  while (1) {
    int rc = nanosleep(&ts,&rem);
    if (rc==0) {
      return;
    } else {
      if (errno==EINTR) {
        ts = rem;
        continue;
      }
      throw_ErrnoException("nanosleep");
    }
  }
}


};


#endif

