// include/charset/to_ascii_letters.hh
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

#ifndef pbe_charset_to_ascii_letters_hh
#define pbe_charset_to_ascii_letters_hh

#include "charset/char_t.hh"

#include <boost/iterator/iterator_facade.hpp>


namespace pbe {


typedef char char_expansion_page_00_t [3];
typedef char char_expansion_page_01_t [3];
typedef char char_expansion_page_02_t [3];
typedef char char_expansion_page_1D_t [2];
typedef char char_expansion_page_1E_t [2];
typedef char char_expansion_page_20_t [3];
typedef char char_expansion_page_21_t [5];
typedef char char_expansion_page_24_t [2];
typedef char char_expansion_page_2C_t [2];
typedef char char_expansion_page_32_t [4];
typedef char char_expansion_page_33_t [5];
typedef char char_expansion_page_FB_t [4];
typedef char char_expansion_page_FF_t [2];
typedef char char_expansion_page_1D4_t [2];
typedef char char_expansion_page_1D5_t [2];
typedef char char_expansion_page_1D6_t [2];

extern char_expansion_page_00_t  to_ascii_letters_page_00  [256];
extern char_expansion_page_01_t  to_ascii_letters_page_01  [256];
extern char_expansion_page_02_t  to_ascii_letters_page_02  [256];
extern char_expansion_page_1D_t  to_ascii_letters_page_1D  [256];
extern char_expansion_page_1E_t  to_ascii_letters_page_1E  [256];
extern char_expansion_page_20_t  to_ascii_letters_page_20  [256];
extern char_expansion_page_21_t  to_ascii_letters_page_21  [256];
extern char_expansion_page_24_t  to_ascii_letters_page_24  [256];
extern char_expansion_page_2C_t  to_ascii_letters_page_2C  [256];
extern char_expansion_page_32_t  to_ascii_letters_page_32  [256];
extern char_expansion_page_33_t  to_ascii_letters_page_33  [256];
extern char_expansion_page_FB_t  to_ascii_letters_page_FB  [256];
extern char_expansion_page_FF_t  to_ascii_letters_page_FF  [256];
extern char_expansion_page_1D4_t to_ascii_letters_page_1D4 [256];
extern char_expansion_page_1D5_t to_ascii_letters_page_1D5 [256];
extern char_expansion_page_1D6_t to_ascii_letters_page_1D6 [256];


inline const char* to_ascii_letters(char32_t c) {
  // Given a Unicode (UCS4) character c, return a pointer to a sequence of ASCII
  // lower-case letters (a-z) that are equivalent in the following sense:
  // - Upper case is mapped to lower case.
  // - Accents (etc) are stripped.
  // - "Compound" letters are decomposed into multiple individial letters (e.g. ae).
  //   (This includes various mathemtical symbols and oddities like VIII, for which there
  //   is a single unicode character.)
  // If the character has no corresponding letters, an empty sequence is returned
  // (e.g. punctuation symbols and letters in other scripts.  Letters from e.g. cyrillic
  // and greek that are homoglyphs to latin letters are not considered equivalent.)
  // The aim of this conversion is to convert a string to something that can be used
  // as a search key for user-supplied search terms.
  // This is based on data extracted from the unicode character database, using the
  // "NFKD" rules.  One oddity is that the German ezsett is not expanded to ss; I don't
  // know why not, or what other oddities there are.  All of the useful conversions are
  // in the various "Latin" pages (see below).
  // The returned pointer points to static data.

  // FIXME it would probably be better to distinguish between NULL, space and other
  // word-breaking punctuation, non-word-breaking punctuation, and non-latin-convertible
  // characters in some way.

  int page = c>>8;
  int point = c&0xff;
  switch (page) {
    case 0x000: return  to_ascii_letters_page_00[point];  // Basic Latin & Latin-1 Supplement
    case 0x001: return  to_ascii_letters_page_01[point];  // Latin Extended-A & Latin Extended-B
    case 0x002: return  to_ascii_letters_page_02[point];  // Latin Extended-B etc.
    case 0x01D: return  to_ascii_letters_page_1D[point];  // Phonetic Extensions etc.
    case 0x01E: return  to_ascii_letters_page_1E[point];  // Latin Extended Additional.
    case 0x020: return  to_ascii_letters_page_20[point];  // General Punctuation etc.
    case 0x021: return  to_ascii_letters_page_21[point];  // Letterlike symbols etc.
    case 0x024: return  to_ascii_letters_page_24[point];  // Enclosed alphanumerics etc.
    case 0x02C: return  to_ascii_letters_page_2C[point];  // Latin Extended-C etc.
    case 0x032: return  to_ascii_letters_page_32[point];  // Enclosed CJK Letters and Months.
    case 0x033: return  to_ascii_letters_page_33[point];  // CJK Compatibility.
    case 0x0FB: return  to_ascii_letters_page_FB[point];  // Alphabetic Presentation Forms etc.
    case 0x0FF: return  to_ascii_letters_page_FF[point];  // Halfwidth and Fullwidth Forms etc.
    case 0x1D4: return to_ascii_letters_page_1D4[point];  // Mathematical Alphanumeric Symbols.
    case 0x1D5: return to_ascii_letters_page_1D5[point];  // (cont.)
    case 0x1D6: return to_ascii_letters_page_1D6[point];  // (cont.)
    default:    return "";
  }
}


template <typename InputIter, typename OutputIter>
inline OutputIter to_ascii_letters(InputIter first, InputIter last, OutputIter result) {
  // Copy Unicode (UCS4) characters in the range first to last to result, converting to ASCII
  // letters as abive, and return an iterator for the end of the result.  Input characters that
  // don't correspond to any ASCII letters are replaced with spaces, except that 0 remains 0.

  for (InputIter i = first; i!=last; ++i) {
    char32_t c = *i;
    if (!c) {
      *(result++) = 0;
    } else {
      const char* l = to_ascii_letters(c);
      if (!*l) {
        *(result++) = ' ';
      } else {
        do {
          *(result++) = *(l++);
        } while (*l);
      }
    }
  }
  return result;
}


template <typename Iter>
class ascii_letter_iterator: public boost::iterator_facade< ascii_letter_iterator<Iter>,
                                                            char,
                                                            boost::forward_traversal_tag,
                                                            char >
{
  // This is an immutable forward iterator that steps through the ascii letters (as above) 
  // that come from the contained iterator.  Punctuation is replaced with spaces; multiple
  // punctuation yeilds multiple spaces.  A null in the input results in a null in the
  // output (but don't try to increment past it - FIXME this is a bit broken).
  // The end-of-input iterator must be supplied to the constructor.  You can get away with
  // passing a fake end-of-input iterator (e.g. NULL) if you can be certain that
  // dereferencing end() is harmless.

  Iter i;
  const char* decomp_ptr;
  Iter end;

  friend class boost::iterator_core_access;

  void increment() {
    if (*decomp_ptr) {
      ++decomp_ptr;
    }
    if (!*decomp_ptr) {
      ++i;
      if (i==end || !*i) {
        decomp_ptr = NULL;
      } else {
        decomp_ptr = to_ascii_letters(*i);
      }
    }
  }

  bool equal(const ascii_letter_iterator& other) const {
    return (i == other.i) && (decomp_ptr == other.decomp_ptr);
  }

  char dereference() const {
    if (!decomp_ptr) {
      return 0;
    }
    char c = *decomp_ptr;
    if (!c) {
      return ' ';
    } else {
      return c;
    }
  }

public:
  ascii_letter_iterator(Iter i_, Iter end_):
    i(i_),
    decomp_ptr(NULL),
    end(end_)
  {
    if (i!=end && *i) {
      decomp_ptr = to_ascii_letters(*i);
    }
  }


  Iter base() const {
    return i;
  }

};


};


#endif

