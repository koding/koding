// csv.cc
// (C) 2008 Philip Endecott
// This file is part of libpbe.  See http://svn.chezphil.org/libpbe/
// This file is distributed under the terms of the Boost Software License v1.0.
// Please see http://www.boost.org/LICENSE_1_0.txt or the accompanying file BOOST_LICENSE.

#include "csv.hh"

#include <string>
#include <iostream>
#include <vector>

using namespace std;


namespace pbe {

template <typename iter>
static string parse_csv_field(iter& i, iter j)
{
  if (i==j) {
    return "";
  }
  string s;
  if (*i == '"') {
    // Quoted:
    ++i;  // initial quote
    while (i != j && *i != '"') {
      if (*i == '\\') {
        ++i;
        if (i==j) {
          break;
        }
      }
      s += *i;
      ++i;
    }
    if (i != j) {
      ++i;  // final quote
    }
  } else {
    // Unquoted:
    while (i != j && *i != ',') {
      if (*i == '\\') {
        ++i;
        if (i==j) {
          break;
        }
      }
      s += *i;
      ++i;
    }
  }
  return s;
}


void parse_csv_line(const string l, vector<string>& v)
{
  v.clear();
  string::const_iterator i = l.begin();
  while (1) {
    v.push_back(parse_csv_field(i, l.end()));
    if (i==l.end()) {
      break;
    }
    if (*i != ',') {
      throw "expecting a comma";
    }
    ++i;
  }
}


};
