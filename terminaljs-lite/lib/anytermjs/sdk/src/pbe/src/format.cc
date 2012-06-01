// src/format.cc
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

#include "format.hh"

#include <string>
#include <cstdarg>
#include <cstdio>
#include <malloc.h>


namespace pbe {


// vasprintf is a GNUism.  We could achieve the same thing using vsnprintf
// in a loop for other C libraries.

#ifdef __GLIBC__

std::string format(const char* fmt,...)
{
  va_list args;
  va_start(args,fmt);
  char* p;
  int r = vasprintf(&p,fmt,args);
  if (r<0) {
    throw "vasprintf failed";
  }
  va_end(args);
  std::string s(p);
  free(p);
  return s;
}

#endif


};

