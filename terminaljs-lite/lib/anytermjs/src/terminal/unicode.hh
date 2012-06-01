// daemon/unicode.hh
// This file is part of Anyterm; see http://anyterm.org/
// (C) 2007 Philip Endecott

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


#ifndef unicode_hh
#define unicode_hh

#include <string>

#include "endian.hh"

#if PBE_BYTE_ORDER == PBE_LITTLE_ENDIAN
#define UCS4_NATIVE "UCS-4LE"
#elif PBE_BYTE_ORDER == PBE_BIG_ENDIAN
#define UCS4_NATIVE "UCS-4BE"
#endif

typedef wchar_t char32_t;
typedef char32_t ucs4_char;
typedef std::basic_string<ucs4_char> ucs4_string;

typedef char utf8_char;
typedef std::basic_string<utf8_char> utf8_string;


#endif
