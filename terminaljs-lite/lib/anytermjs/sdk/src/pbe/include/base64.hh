// include/base64.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2008 Philip Endecott

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

#ifndef libpbe_base64_hh
#define libpbe_base64_hh

#include <cctype>
#include <string>
#include <iterator>
#include <algorithm>

#include <boost/cstdint.hpp>

#include "init_array.hh"
#include "compiler_magic.hh"


// Base64 decoding
// ===============
//
// As specified by RFC2045 section 6.8.


namespace pbe {


// Thrown if invalid base64 data is encountered while decoding:
struct InvalidBase64 {};


// An iterator adaptor that does base64 decoding.
// It wraps an underlying iterator that iterates over the bytes of the
// base64-coded data, providing an iterator over the bytes of the
// decoded data.  Both iterators are input iterators.


template <typename Iter>
class base64_iter
{

// The implementation stores 3 decoded bytes internally and iterates
// through them until they're all used; it then reads and decodes 
// another 4 raw bytes from the input.

// Note that this iterator expects you to alternately dereference and
// increment it.  If you increment without dereferencing, bad things
// will happen.  (Multiple dereferencing without incrementing is OK.)

public:
  typedef std::input_iterator_tag iterator_category;
  typedef boost::uint8_t          value_type;
  typedef std::ptrdiff_t          difference_type;
  typedef boost::uint8_t&         reference;
  typedef boost::uint8_t*         pointer;

  base64_iter() {}

  // Construct using the underlying iterator.
  // This takes a second iterator pointing to the end of the data;
  // this could be made optional for cases where it's not feasible to
  // provide it (e.g. an istream_iterator), but in this case it's not
  // clear how to detect and report end-of-data.
  base64_iter(Iter i_, Iter i_end_):
    i(i_),
    i_end(i_end_),
    pos(3),
    bytes(0)
  {}

  boost::uint8_t operator*() {
    maybe_get_more_bytes();
    return bytes[pos];
  }

  base64_iter& operator++() {
    ++pos;
    return *this;
  }

  void operator++(int) {
    ++pos;
  }

  bool operator==(const base64_iter& other) const {
    return i==other.i && pos==other.pos;
  }

  bool operator!=(const base64_iter& other) const {
    return !operator==(other);
  }

private:
  Iter i;
  Iter i_end;
  int pos;
  init_array<boost::uint8_t,3> bytes;

  void maybe_get_more_bytes() {
    if (pos > 2) {
      get_3bytes();
    }
  }

  void get_3bytes() {
    int h0 = get_sixbits();
    int h1 = get_sixbits();
    int h2 = get_sixbits();
    int h3 = get_sixbits();
    // The format of each 4-character group can be:
    // XXXX : 3 bytes
    // XXX= : 2 bytes
    // XX== : 1 byte
    // There will always be 4 characters in the group.
    // get_sixbits returns -1 if it sees an =.
    IF_LIKELY(h0>=0 && h1>=0 && h2>=0 && h3>=0) {
      bytes[0] = (h0<<2) | (h1>>4);
      bytes[1] = ((h1&15)<<4) | (h2>>2);
      bytes[2] = ((h2&3)<<6) | (h3);
      pos -= 3;
      return;
    }
    // In the "short" cases we put the bytes that we have received at
    // the end of the bytes array.  This means that once they've been
    // read, end-of-data will be readed with i==i_end && pos==3.  This
    // should equal the base64_iter constructed from the underlying end().
    if (h0>=0 && h1>=0 && h2>=0 && h3==-1) {
      bytes[1] = (h0<<2) | (h1>>4);
      bytes[2] = ((h1&15)<<4) | (h2>>2);
      pos -= 2;
      return;
    }
    if (h0>=0 && h1>=0 && h2==-1 && h3==-1) {
      bytes[2] = (h0<<2) | (h1>>4);
      pos -= 1;
      return;
    }
    throw InvalidBase64();
  }

  int get_sixbits() {
    char c;
    do {
      if (i==i_end) {
        return 0;
      }
      c = *i;
      ++i;
    } while (std::isspace(c));
    if (c>='a' && c<='z') return c-'a'+26;
    if (c>='A' && c<='Z') return c-'A';
    if (c>='0' && c<='9') return c-'0'+52;
    if (c=='+') return 62;
    if (c=='/') return 63;
    if (c=='=') return -1;
    throw InvalidBase64();
      // The RFC says that we "must ignore" other characters, but a
      // couple of lines later says that they "probably indicate a
      // transmission error" ... "rejection might be appropriate".
  }
};




// Decode a std::string

inline std::string decode_base64(const std::string& data)
{
  std::string result;
  result.reserve(data.length()*3/4);
  typedef base64_iter<std::string::const_iterator> in_iter_t;
  in_iter_t data_begin(data.begin(), data.end());
  in_iter_t data_end(data.end(), data.end());
  typedef std::back_insert_iterator<std::string> out_iter_t;
  out_iter_t result_inserter(result);
  std::copy(data_begin, data_end, result_inserter);
//for (; data_begin != data_end; ++data_begin) { *(result_inserter++) = *data_begin; }
  return result;
}



};


#endif

