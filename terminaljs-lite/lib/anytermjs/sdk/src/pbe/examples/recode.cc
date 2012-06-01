// examples/recode.cc
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
// Demo program for libpbe Recoder class
// C++ interface to the recode library
// Convert between character sets e.g. ISO-8859-n to/from unicode
// Also CR to CRLF, do base64 coding and the like

#include "Recoder.hh"

// Create a converter as a global object of class Recoder.
// (There is startup overhead; doesn't have to be global, but is probably
// best in most cases.  Don't create and destroy them all over the place)

// In this case, convert LF line endings (the default) to Microsfot-style
// CR-LF line endings.

Recoder lf_to_crlf ( "", "/CR-LF" );

// Parameters to constructor are "from" and "to" character sets.
// See recode documentation for details (info recode)
// Just a few examples:
// ASCII        7-bit ASCII
// ISO-8859-1   8-bit ISO-8859-1 (Latin 1; Western European languages)
// ISO-8859-15  8-bit ISO-8859-15 (ditto plus Euro symbol)
// UTF-8        8-bit Unicode
// UCS-2        16-bit Unicode
// /CR          CR for end-of-line (Apple)
// /CR-LF       CR-LF for end-of-line (Microsoft)
//              [LF is default, use empty string]
// /Base64      Base 64 encoding (used for email attachments)
// /Decimal-1   Output decimal values for each character (for debugging)

// Having created to Recoder object, use it as a function (on strings) to
// actually do the conversion:

#include <string>
#include <iostream>
using namespace std;

int main(int argc, char* argv[])
{
  string s = "Hello\nWorld\n";
  string t = lf_to_crlf(s);
  cout << s << ' ' << t;
}

// Need to link with -lrecode

// Pipe this program into "od -a" to see what is going on.
