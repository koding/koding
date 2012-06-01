// src/Iconvert.hh
// This file is part of libpbe; see http://decimail.org and http://anyterm.org
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

// C++ wrapper around iconv.

// This is not thread-safe in the sense that an Iconver object cannot
// be used safely from multiple threads; each thread must have its own
// object.

#ifndef libpbe_Iconver_hh
#define libpbe_Iconver_hh

#include <iconv.h>

#include <stdlib.h>

#include <string>

#include <boost/scoped_array.hpp>

#include "Exception.hh"


#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__sun__)
// Previously __APPLE__ was included in this list; presumably they have
// changed their headers.  If you have an older system you may need to put
// it back.
#define ICONV_ARG2_IS_CONST
#endif


namespace pbe {


enum iconv_errmode { reversible,   // Throw if an input character cannot be reversibly converted.
                     complete,     // Throw if the input is not complete.
                     valid,        // Throw if the input is not valid.
                     permissive    // Don't throw.
                   };  // TODO there are combinations of these....

// The template parameter char types don't need to be the actual types of the character sets, 
// since iconv just deals with lumps of bytes; they just need to correspond to the types of the 
// input and output to operator().
template <iconv_errmode errmode = valid, typename from_char = char, typename to_char = char>
class Iconver {

public:
  Iconver(std::string &from_charset, std::string &to_charset) {
    iconverter = iconv_open(to_charset.c_str(), from_charset.c_str());
    if (iconverter==reinterpret_cast<iconv_t>(-1)) {
      throw InvalidCharset();
    }
  }
  Iconver(const char *from_charset,const char *to_charset)
  {
    iconverter = iconv_open(to_charset, from_charset);
    if (iconverter==reinterpret_cast<iconv_t>(-1)) {
      throw InvalidCharset();
    }
  }

  ~Iconver() {
    int rc = iconv_close(iconverter);
    if (rc==-1) {
      // pbe::throw_ErrnoException("iconv_close()");
      // Don't throw an exception from a destructor, in case it has been invoked 
      // during exception processing.
      // (TODO is there a better solution to this?)
    }
  }

  std::basic_string<to_char> operator()(std::basic_string<from_char> i) {
    return operator()(i.data(),i.size());
  }

  std::basic_string<to_char> operator()(const from_char* i, size_t l) {
    if (carry.size()) {
      std::basic_string<from_char> s = carry;
      s.append(i,l);
      carry.clear();
      i = s.data();
      l = s.size();
    }
    const size_t bytes_in = sizeof(from_char) * l;
    const size_t obuf_sz = l * 2; // do multiple chunks if necessary
    const size_t buf_bytes = obuf_sz * sizeof(to_char);
    boost::scoped_array<to_char> obuf (new to_char[obuf_sz]);
    std::basic_string<to_char> o;

#ifdef ICONV_ARG2_IS_CONST
    const char* ip = reinterpret_cast<const char*>(i);
#else
    char* ip = reinterpret_cast<char*>(const_cast<from_char*>(i));
#endif

    size_t in = bytes_in;

    do {
      char* op = reinterpret_cast<char*>(obuf.get());
      size_t on = buf_bytes;
    
      int rc = iconv(iconverter, &ip, &in, &op, &on);
      if (rc==-1) {
        if (errno==E2BIG) {
          // Output buffer is full.  We'll go around the loop again.
        } else if (errno==EILSEQ) {
          // An invalid multibyte sequence has been found.
          if (errmode==permissive) {
            // Skip the offending character and continue.
            // (iconv stores any valid converted data from before the error and updates
            // the pointers correctly in this case.)
            ip += sizeof(from_char);
            in -= sizeof(from_char);
          } else {
            throw InvalidInput();
          }
        } else if (errno==EINVAL) {
          // An incomplete multibyte sequence has been found at the end of the input.
          if (errmode==complete) {
            throw IncompleteInput();
          } else {
            carry = std::basic_string<from_char>(reinterpret_cast<const from_char*>(ip),in/sizeof(from_char));
            in = 0;
          }
        } else {
          pbe::throw_ErrnoException("iconv()");
        }
      } else if (rc>0) {
        if (errmode==reversible) {
          throw NotReversible();
        }
      }
      o += std::basic_string<to_char>(obuf.get(), (buf_bytes - on)/sizeof(to_char));
    } while (in>0);

    return o;
  }


  void flush() {
    // Caller believes that the input is complete; throws if a multi-byte character is outstanding.
    if (errmode==permissive) {
      reset();
    } else if (carry.size()) {
      throw IncompleteInput();
    }
  }


  void reset() {
    // Clear any outstanding partial multi-byte character.
    carry.clear();
  }


  class InvalidCharset: public pbe::StrException {
  public:
    InvalidCharset(): pbe::StrException("Invalid character set or unsupported conversion") {}
  };

  class InvalidInput: public pbe::StrException {
  public:
    InvalidInput(): pbe::StrException("Invalid input to Iconv") {}
  };

  class IncompleteInput: public pbe::StrException {
  public:
    IncompleteInput(): pbe::StrException("Incomplete multi-byte input to Iconv") {}
  };

  class NotReversible: public pbe::StrException {
  public:
    NotReversible(): pbe::StrException("Non-reversible input to Iconv") {}
  };

private:
  iconv_t iconverter;
  std::basic_string<from_char> carry;
};


};

#endif
