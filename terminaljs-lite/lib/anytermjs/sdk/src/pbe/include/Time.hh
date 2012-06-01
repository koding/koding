// src/Time.hh
// This file is part of libpbe; see http://decimail.org
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

#ifndef libpbe_Time_hh
#define libpbe_Time_hh

#include <iostream>

#include <time.h>


namespace pbe {

  struct Time {

    uint8_t hour;
    uint8_t minute;
    uint8_t second;

    Time() {}

    Time(int hour_, int minute_, int second_):
      hour(hour_), minute(minute_), second(second_) {}

    bool operator<(const Time& rhs) const {
      return (hour<rhs.hour)
          || (hour==rhs.hour && minute<rhs.minute)
          || (hour==rhs.hour && minute==rhs.minute && second<rhs.second);
    }

    bool operator==(const Time& rhs) const {
      return (hour==rhs.hour && minute==rhs.minute && second==rhs.second);
    }

  };


  inline std::ostream& operator<<(std::ostream& strm, Time t) {
    strm << static_cast<int>(t.hour) << ":" << static_cast<int>(t.minute)
         << ":" << static_cast<int>(t.second);
    return strm;
  }

}


#endif
