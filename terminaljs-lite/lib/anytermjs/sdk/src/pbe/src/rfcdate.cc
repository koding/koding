// rfcdate.cc
// This file is part of libpbe; see http://anyterm.org/
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


#include <string>

#include <time.h>

using namespace std;


namespace pbe {


string rfc_date(void)
// RFC2616 cites RFC1123 for date/time format, which cites RFC822 with
// clarifications.
{
  char s[36];
  time_t t;
  time(&t);
  struct tm tm;
  localtime_r(&t,&tm);
  strftime(s,sizeof(s),"%a, %d %b %Y %H:%M:%S %z",&tm);
  return s;
}


};
