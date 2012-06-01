// src/DateTime.hh
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

#ifndef libpbe_DateTime_hh
#define libpbe_DateTime_hh

#include <iostream>

#include <time.h>

#include "Date.hh"
#include "Time.hh"
#include "Exception.hh"


namespace pbe {

  struct DateTime {

    Date date;
    Time time;

    DateTime() {}

    DateTime(int year, int month, int day,
         int hour=0, int minute=0, int second=0):
      date(year,month,day),
      time(hour,minute,second) {}

    DateTime(time_t t) {
      struct tm b;
      localtime_r(&t, &b);  // Or gmtime_r() ???
      date.year = b.tm_year + 1900;
      date.month = b.tm_mon + 1;
      date.day = b.tm_mday;
      time.hour = b.tm_hour;
      time.minute = b.tm_min;
      time.second = b.tm_sec;
    }

    DateTime(Date date_):
      date(date_), time(0,0,0) {}

    DateTime(Date date_, Time time_):
      date(date_), time(time_) {}

    bool operator<(const DateTime& rhs) const {
      return (date<rhs.date)
          || (date==rhs.date && time<rhs.time);
    }


    void to_struct_tm(struct tm& b) const {
      b.tm_year = date.year - 1900;
      b.tm_mon  = date.month - 1;
      b.tm_mday = date.day;
      b.tm_hour = time.hour;
      b.tm_min  = time.minute;
      b.tm_sec  = time.second;
    }

    time_t to_time_t(void) const {
      struct tm b;
      to_struct_tm(b);
      time_t t = mktime(&b);
      if (t==-1) {
        throw pbe::StrException("mktime() input is invalid or out of range");
      }
      return t;
    }

    time_t utc_to_time_t(void) const {
      struct tm b;
      to_struct_tm(b);
      time_t t = timegm(&b);
      if (t==-1) {
        throw pbe::StrException("mktime() input is invalid or out of range");
      }
      return t;
    }

    int day_of_week(void) const {
      struct tm b;
      to_struct_tm(b);
      time_t t = timegm(&b);
      if (t==-1) {
        throw pbe::StrException("mktime() input is invalid or out of range");
      }
      return b.tm_wday+1;
    }

  };


  inline std::ostream& operator<<(std::ostream& strm, const DateTime& dt) {
    strm << dt.date << " " << dt.time;
    return strm;
  }

}


#endif
