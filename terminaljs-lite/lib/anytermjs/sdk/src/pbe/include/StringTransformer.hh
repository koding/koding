// src/StringTransformer.hh
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
#ifndef libpbe_StringTransformer_hh
#define libpbe_StringTransformer_hh

#include <string>
#include <vector>
using namespace std;

class StringTransformer {
private:
  int char_idx(char c) const { return (unsigned char)(c); }

public:
  StringTransformer(void):
    transformation(256)
  {
    for(int c=0; c<256; ++c) {
      transformation[c] = c;
    }
  }

  void add_cc_rule(char from, char to)
  {
    transformation[char_idx(from)]=to;
  }

  void add_cs_rule(char from, string to)
  {
    transformation[char_idx(from)]=to;
  }

  template<typename CharToStringFunc>
  void add_cf_rule(char from, const CharToStringFunc xform)
  {
    transformation[char_idx(from)]=xform(from);
  }

  template<typename CharPredicate>
  void add_pc_rule(const CharPredicate from, char to)
  {
    for(int c=0; c<256; ++c) {
      if (from(c)) {
	transformation[c] = to;
      }
    }
  }

  template<typename CharPredicate>
  void add_ps_rule(const CharPredicate from, string to)
  {
    for(int c=0; c<256; ++c) {
      if (from(c)) {
	transformation[c] = to;
      }
    }
  }

  template<typename CharPredicate, typename CharToStringFunc>
  void add_pf_rule(const CharPredicate from, const CharToStringFunc xform)
  {
    for(int c=0; c<256; ++c) {
      if (from(c)) {
	transformation[c] = xform(c);
      }
    }
  }

  string operator()(const string& s) const
  {
    string r;
    for(string::const_iterator i=s.begin();
	i!=s.end(); ++i) {
      r.append(transformation[char_idx(*i)]);
    }
    return r;
  }

private:
  vector<string> transformation;
};



class EscapeInserter: public StringTransformer {
public:
  EscapeInserter(string chars_to_escape, char escape_char = '\\')
  {
    string escaped("  ");
    escaped[0]=escape_char;
    for (string::const_iterator i=chars_to_escape.begin();
	 i!=chars_to_escape.end(); ++i) {
      escaped[1]=*i;
      add_cs_rule(*i,escaped);
    }
  }
};



#endif
