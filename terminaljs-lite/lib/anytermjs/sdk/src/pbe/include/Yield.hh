// include/Yield.hh
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

#ifndef libpbe_Yield_hh
#define libpbe_Yield_hh

// The file implements a Futex-like class which simply calls sched_yield().

#include <sched.h>

#include "Exception.hh"
#include "compiler_magic.hh"

namespace pbe {


struct Yield {

  Yield(PBE_UNUSED_ARG(int& val)) {}
  ~Yield() {}

  void wait(PBE_UNUSED_ARG(int expected)) {
    int r = ::sched_yield();
    if (r==-1) {
      throw_ErrnoException("futex(FUTEX_WAIT)");
    }
  }

  bool timed_wait(PBE_UNUSED_ARG(int expected), const timespec& timeout) {
  // TODO detect timeout
    wait(expected);
    return true;
  }

  bool timed_wait(PBE_UNUSED_ARG(int expected), float timeout) {
  // TODO detect timeout
    wait(expected);
    return true;
  }

  // Wake up to n waiters; returns the number woken.
  int wake(int n=1) {
    // Hmm, how much does the return value matter?
    return n;
  }
};


};


#endif

