// common/Attributes.hh
// This file is part of AnyTerm; see http://anyterm.org/
// (C) 2006-2007 Philip Endecott

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

#ifndef Attributes_hh
#define Attributes_hh


struct Attributes {
  unsigned fg         : 3;
  unsigned bg         : 3;
  unsigned halfbright : 1;
  unsigned bold       : 1;
  unsigned underline  : 1;
  unsigned blink      : 1;
  unsigned inverse    : 1;

  Attributes():
    fg(7), bg(0),
    halfbright(false), bold(false), underline(false), blink(false), inverse(false)
  {}

  bool operator==(const Attributes& other) const {
    return fg==other.fg                 && bg==other.bg
        && halfbright==other.halfbright && bold==other.bold
        && underline==other.underline   && blink==other.blink
        && inverse==other.inverse;
  }
  bool operator!=(const Attributes& other) const {
    return ! operator==(other);
  }
};


#endif
