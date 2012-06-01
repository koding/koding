// libpbe/include/compiler_magic.hh
// This file is part of libpbe; see http://anyterm.org/
// (C) 2007-2008 Philip Endecott

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


// Wrappers around various gcc thingies.


#ifndef compiler_magic_hh
#define compiler_magic_hh

#ifdef __GNUC__

// Supress unused-argument warning:
#define PBE_UNUSED_ARG(a) a __attribute__((unused))

// Give status branch prediction hints:
#define IF_LIKELY(c)   if(__builtin_expect(c,1))
#define IF_UNLIKELY(c) if(__builtin_expect(c,0))

// Warn if function result is ignored:
#define PBE_WARN_RESULT_IGNORED __attribute__ ((warn_unused_result))

#else

#define PBE_UNUSED_ARG(a) a
#define IF_LIKELY(c)   if(c)
#define IF_UNLIKELY(c) if(c)
#define PBE_WARN_RESULT_IGNORED

#endif

#endif
