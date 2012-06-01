// src/Date.hh
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

#ifndef libpbe_Date_hh
#define libpbe_Date_hh

#include <iostream>

#include <time.h>

#include <stdint.h>


namespace pbe {


  static int days_in_month_[] = { 31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

  struct Date {

    uint16_t year;
    uint8_t month;
    uint8_t day;

    Date() {}

    Date(int year_, int month_, int day_):
      year(year_), month(month_), day(day_) {}

    Date(time_t t) {
      struct tm b;
      localtime_r(&t, &b);
      year = b.tm_year + 1900;
      month = b.tm_mon + 1;
      day = b.tm_mday;
    }

    bool operator<(const Date& rhs) const {
      return (year<rhs.year)
          || (year==rhs.year && month<rhs.month)
          || (year==rhs.year && month==rhs.month && day<rhs.day);
    }

    bool operator==(const Date& rhs) const {
      return (year==rhs.year && month==rhs.month && day==rhs.day);
    }

    bool operator!=(const Date& rhs) const {
      return !operator==(rhs);
    }

    bool is_leap_year(void) const {
      return !(year%4) && ((year%100) || !(year%400));
    }

    int days_in_month(void) const {
      if (month==2) {
        if (is_leap_year()) {
          return 29;
        } else {
          return 28;
        }
      } else {
        return days_in_month_[month-1];
      }
    }

    int day_of_week(void) const;

    Date& operator++() {
      if (day<days_in_month()) {
        ++day;
      } else {
        day = 1;
        if (month<12) {
          ++month;
        } else {
          month=1;
          ++year;
        }
      }
      return *this;
    }

    Date& operator--() {
      if (day>1) {
        --day;
      } else {
        if (month>1) {
          --month;
        } else {
          month=12;
          --year;
        }
        day = days_in_month();
      }
      return *this;
    }

  };


  inline std::ostream& operator<<(std::ostream& strm, Date d) {
    strm << d.year << "-" << static_cast<int>(d.month) << "-" << static_cast<int>(d.day);
    return strm;
  }

}


#endif
