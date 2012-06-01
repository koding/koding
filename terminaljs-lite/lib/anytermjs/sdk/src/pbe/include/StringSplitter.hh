// src/StringSplitter.hh
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
#ifndef libpbe_StringSplitter_hh
#define libpbe_StringSplitter_hh

#include <string>
using namespace std;


class StringSplitter {
protected:
  const string& str;

  std::string::size_type start;
  std::string::size_type end;
  bool init;
  bool last;
  bool past_end;

public:
  StringSplitter ( const string& s ):
    str(s), start(0), init(false), last(false), past_end(false) {}

  virtual ~StringSplitter() {}

  bool exhausted(void) const {
    return past_end;
  }

  string operator*(void) /*const*/ {
    if (!init) {
      find_end();
      init=true;
    }
    return str.substr(start,end-start);
  }

  void operator++(void) {
    if (last) {
      past_end=true;
    } else {
      if (!init) {
	find_end();
	init=true;
      }
      find_next_start();
      find_end();
    }
  }

private:
  virtual void find_next_start(void) = 0;
  virtual void find_end(void) = 0;

};



class StringSplitterSeq: public StringSplitter {
private:
  const string split_seq;

public:
  StringSplitterSeq ( const string& s, const string ss ):
    StringSplitter(s), split_seq(ss) {}

private:
  void find_next_start(void) {
    start = end+split_seq.size();
  }

  void find_end(void) {
    end = str.find(split_seq,start);
    if (end==str.npos) {
      end=str.size();
      last=true;
    }
  }
};



class StringSplitterAny: public StringSplitter {
private:
  const string split_chars;

public:
  StringSplitterAny ( const string& s, const string sc ):
    StringSplitter(s), split_chars(sc) {}

private:
  void find_next_start(void) {
    start = end+1;
  }

private:
  void find_end(void) {
    end = str.find_first_of(split_chars,start);
    if (end==str.npos) {
      end=str.size();
      last=true;
    }
  }
};


#endif
