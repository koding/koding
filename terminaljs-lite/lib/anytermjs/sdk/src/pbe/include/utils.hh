// src/utils.hh
// This file is part of libpbe; see http://decimail.org
// (C) 2004-2007 Philip Endecott

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

#ifndef libpbe_utils_hh
#define libpbe_utils_hh

#include "StringTransformer.hh"

#include <string>
//#include <list>


namespace pbe {

//string int_to_string(int i);
//string float_to_string(float f);
//string double_to_string(double f);

//int string_to_int(string s);
//float string_to_float(string s);
//double string_to_double(string s);

int hex_string_to_int(string s);

int maybe_hex_string_to_int(string s);

extern std::string escape_for_dquoted_string(std::string s);
extern std::string escape_for_squoted_string(std::string s);
extern std::string escape_for_regexp(std::string s);

//string escape_for_xpath_string(string s);

//extern const StringTransformer& to_upper;

//extern const StringTransformer& to_lower;

//extern const StringTransformer& lf_to_crlf;

template <typename T>  // contaier<string>
std::string join(const T& strs, std::string joiner) {
  if (strs.empty()) {
    return "";
  }
  typename T::const_iterator i = strs.begin();
  std::string s = *i;
  ++i;
  while (i != strs.end()) {
    s += joiner;
    s += *i;
    ++i;
  }
  return s;
}

//string trim_whitespace (string s);

//string normalise_whitespace (string s);

//bool starts_with ( string s, string prefix );

//void check_alphanumeric ( string s );
//void check_numeric ( string s );

};

#endif
