// common/diff.hh
// This file is part of Anyterm; see http://anyterm.org/
// (C) 2005 Philip Endecott

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


#ifndef diff_hh
#define diff_hh

#include <string>
#include <list>

#include "unicode.hh"


namespace DiffAlgo {

  // "Diff Algorithm" i.e. the algorithm used by the diff program.

  // Unlike the diff program, this algorithm can do comparisons on
  // sequences of any types, not just lines.  But the template
  // specialisation is hidden inside the .cc file, so if you want to
  // do anything other character-by-character (string) comparisons
  // you'll need to make some changes there.  Don't be put off, it's
  // not hard.  (If you want to do line-by-line comparisons, you'll
  // want to implement a line type with an efficient equality
  // comparison operator, e.g. a precomputed hash.  The same applies
  // for other complex types.)

  // It's also possible to find a measure of similarity of two
  // sequences - the "distance" between them - using this code.
  // Again, you'll need to delve into the .cc file for the details.

  // Implementation details are also in the .cc file.

  // Given two input string, say "hello world" and "goodbye world",
  // the algorithm finds and returns a sequence of fragments,
  // indicating for each whether it was from the first string, or from
  // the second string, or was common to both strings:

  // From A: "hell"
  // From B:        "g"     "odbye"
  // Common:            "o"         " world"

  // Here are the types that define this return format:


  enum fragment_tag { from_a, from_b, common };

  template <typename SEQ>
  struct fragment_seq {
    typedef std::list<std::pair<fragment_tag,SEQ> > Type;
  };


  // String diffs:

  typedef fragment_seq<std::string>::Type string_fragment_seq;

  typedef fragment_seq<ucs4_string>::Type ucs4_string_fragment_seq;

  // Here is the prototype for the diff function.  It returns its
  // result via an "out" parameter:

  
  void string_diff ( const std::string& A, const std::string& B,
		     string_fragment_seq& result );

  void ucs4_string_diff ( const ucs4_string& A, const ucs4_string& B,
	                  ucs4_string_fragment_seq& result );


};


  
#endif
