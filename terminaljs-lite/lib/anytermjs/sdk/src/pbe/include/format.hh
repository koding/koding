// include/format.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2009 Philip Endecott

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

#ifndef libpbe_format_hh
#define libpbe_format_hh

#include <string>


// pbe::format is an sprintf-like function that returns a std::string.


namespace pbe {


extern std::string format(const char* fmt,...) __attribute__ ((format (printf, 1, 2)));


};


#endif

