// src/ci_string.hh
// This file is part of libpbe; see http://decimail.org
// (C) 2004 Philip Endecott

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
#ifndef libpbe_ci_string_hh
#define libpbe_ci_string_hh

#include <ctype.h>
#include <strings.h>
#include <string>

using namespace std;


// This code is from http://www.gotw.ca/gotw/029.htm
// It seems to be in the public domain (usenet posting)

struct ci_char_traits : public char_traits<char> {
  static bool eq( char c1, char c2 ) {
    return toupper(c1) == toupper(c2);
  }
  
  static bool ne( char c1, char c2 ) {
    return toupper(c1) != toupper(c2); 
  }

  static bool lt( char c1, char c2 ) {
    return toupper(c1) <  toupper(c2);
  }

  static int compare( const char* s1, const char* s2, size_t n ) {
    return strncasecmp( s1, s2, n );
  }

  static const char* find( const char* s, int n, char a ) {
    while( n-- > 0 && toupper(*s) != toupper(a) ) {
      ++s;
    }
    return s;
  }
};


typedef basic_string<char, ci_char_traits> ci_string;

// End of code from gowt.ca


string to_string(const ci_string& s);

ci_string to_ci_string(const string& s);



#endif
