// include/segv_backtrace.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/trunk
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

#ifndef libpbe_segv_backtrace_hh
#define libpbe_segv_backtrace_hh


// Call this to install a signal handler that will report a
// backtrace to stderr on segfault, bus error, illegal instruction
// and FP exception.

void get_backtrace_on_segv();


#endif
