// src/utils.cc
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

#include "utils.hh"

#include "Exception.hh"

#if 0
#include <netinet/in.h>
#include <sstream>
#endif

#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string/replace.hpp>
#include <boost/algorithm/string/classification.hpp>

using namespace std;


namespace pbe {

#if 0
string int_to_string(int i)
{
  ostringstream s;
  s << i;
  return s.str();
}

string float_to_string(float f)
{
  char buf[20];
  unsigned int nchars = snprintf(buf,sizeof(buf),"%g",f);
  if (nchars>=sizeof(buf)) {
    throw "float doesn't fit in buffer";
  }
  return buf;
}

string double_to_string(double f)
{
  char buf[20];
  unsigned int nchars = snprintf(buf,sizeof(buf),"%g",f);
  if (nchars>=sizeof(buf)) {
    throw "float doesn't fit in buffer";
  }
  return buf;
}
#endif

class NotANumber: public Exception {
private:
  string numstr;
  string base;
public:
  NotANumber(string ns, string b): numstr(ns), base(b) {}
  void report(ostream& s) const {
    s << '"' << numstr << "\" is not a " << base << " number" << endl;
  }
};


#if 0
int string_to_int(string s)
{
  if (s.size()==0) {
    throw NotANumber(s,"decimal");
  }
  char* endptr;
  int i=strtol(s.c_str(),&endptr,10);
  if (*endptr) {
    throw NotANumber(s,"decimal");
  }
  return i;
}


float string_to_float(string s)
{
  if (s.size()==0) {
    throw NotANumber(s,"floating point");
  }
  char* endptr;
  float f=strtof(s.c_str(),&endptr);
  if (*endptr) {
    throw NotANumber(s,"floating point");
  }
  return f;
}


double string_to_double(string s)
{
  if (s.size()==0) {
    throw NotANumber(s,"floating point");
  }
  char* endptr;
  double d=strtod(s.c_str(),&endptr);
  if (*endptr) {
    throw NotANumber(s,"floating point");
  }
  return d;
}
#endif

int hex_string_to_int(string s)
{
  if (s.size()==0) {
    throw NotANumber(s,"hex");
  }
  char* endptr;
  int i=strtol(s.c_str(),&endptr,16);
  if (*endptr) {
    throw NotANumber(s,"hex");
  }
  return i;
}


int maybe_hex_string_to_int(string s)
{
  if (s.substr(0,2)=="0x") {
    return hex_string_to_int(s.substr(2));
  } else {
    return boost::lexical_cast<int>(s);
  }
}


static string 
prefix_backslash(const boost::iterator_range<std::string::const_iterator>& Match )
{
  return "\\"+string(Match.begin(),Match.end());
}


string escape_for_dquoted_string(string s)
{
  return boost::find_format_all_copy(s,
           boost::token_finder(boost::is_any_of("\\\"")),
           prefix_backslash);
}

string escape_for_squoted_string(string s)
{
  return boost::find_format_all_copy(s,
           boost::token_finder(boost::is_any_of("\\\'")),
           prefix_backslash);
}

string escape_for_regexp(string s)
{
  return boost::find_format_all_copy(s,
           boost::token_finder(boost::is_any_of("/*+?{().^$\\[")),
           prefix_backslash);
}


#if 0
class EscapeForQuotedString: public EscapeInserter {
public:
  EscapeForQuotedString(void): EscapeInserter("\\\"") {}
};



class EscapeForSQuotedString: public EscapeInserter {
public:
  EscapeForSQuotedString(void): EscapeInserter("\\\'") {}
};



class EscapeForRegexp: public EscapeInserter {
public:
  EscapeForRegexp(void): EscapeInserter("/*+?{().^$\\[") {}
};

const StringTransformer& escape_for_regexp = EscapeForRegexp();


class ReplaceSquoteWithHack: public StringTransformer {
public:
  ReplaceSquoteWithHack(void) {
    add_cs_rule('\'',"',\"'\",'");
  }
};

string escape_for_xpath_string(string s)
{
  if (s.find('\'')==s.npos) {
    return "\'"+s+"\'";
  }
  if (s.find('\"')==s.npos) {
    return "\""+s+"\"";
  }
  {
    static ReplaceSquoteWithHack replace_squote_with_hack;
    return "concat('" + replace_squote_with_hack(s) + "')";
  }
}



class ToUpper: public StringTransformer {
public:
  ToUpper(void) {
    for(int c=0; c<256; ++c) {
      add_cc_rule(c,toupper(c));
    }
  }
};

const StringTransformer& to_upper = ToUpper();


class ToLower: public StringTransformer {
public:
  ToLower(void) {
    for(int c=0; c<256; ++c) {
      add_cc_rule(c,tolower(c));
    }
  }
};

const StringTransformer& to_lower = ToLower();


class LfToCrlf: public StringTransformer {
public:
  LfToCrlf(void) {
    add_cs_rule('\n',"\r\n");
  }
};

const StringTransformer& lf_to_crlf = LfToCrlf();


string join(const list<string>& strs, string joiner)
{
  if (strs.size()==0) {
    return "";
  }
  string j;
  list<string>::const_iterator i=strs.begin();
  while(1) {
    j+=(*i);
    ++i;
    if (i==strs.end()) {
      break;
    } else {
      j+=joiner;
    }
  }
  return j;
}


string trim_whitespace (string s)
{
  string::size_type start = s.find_first_not_of("\r\n \t");
  if (start==s.npos) {
    return "";
  }
  unsigned int end = s.find_last_not_of("\r\n \t");
  return s.substr(start,(end-start)+1);
}


string normalise_whitespace (string s)
{
  string r;
  bool skip_spaces=true;
  bool add_space=false;

  for(unsigned int i = 0; i<s.length(); ++i) {
    char c = s[i];
    if (c==' ' || c=='\t' || c=='\r' || c=='\n') {
      if (skip_spaces) {
      } else {
	skip_spaces=true;
	add_space=true;
      }
    } else {
      if (add_space) {
	r.append(1,' ');
	add_space=false;
      }
      r.append(1,c);
      skip_spaces=false;
    }
  }
  return r;
}


bool starts_with ( string s, string prefix )
{
  return s.substr(0,prefix.length())==prefix;
}


void check_alphanumeric ( string s )
{
  string::size_type p = s.find_first_not_of("abcdefghijklmnopqrstuvwxyz"
			                    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			                    "0123456789_");
  if (p!=s.npos) {
    throw "Not alphanumeric";
  }
}


void check_numeric ( string s )
{
  string::size_type p = s.find_first_not_of("0123456789");
  if (p!=s.npos) {
    throw "Not numeric";
  }
}
#endif

};

