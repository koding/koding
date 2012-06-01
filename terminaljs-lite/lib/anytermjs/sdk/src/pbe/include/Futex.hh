// include/Futex.hh
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

#ifndef libpbe_Futex_hh
#define libpbe_Futex_hh

// The file implements a Futex class, which is a simple wrapper around 
// the futex syscall.
// Futex is supported on Linux 2.6 but not older kernels.  If you want to
// run on a 2.4 kernel you need to compile with SUPPORT_LINUX_2_4 defined.
// This will supress the content of this file and the things that use it 
// will fall back to something else (as they do on non-Linux platforms).

#if defined(__linux__) && !defined(SUPPORT_LINUX_2_4)

#define PBE_HAVE_FUTEX

#include <linux/futex.h>
#include <errno.h>
#include <cmath>

#include <boost/static_assert.hpp>

#include "missing_syscalls.hh"
#include "Exception.hh"

namespace pbe {


template <typename INT_T = int>
struct Futex {

  BOOST_STATIC_ASSERT(sizeof(INT_T)==sizeof(int));

  int* const valptr;

  Futex(INT_T& val): valptr(reinterpret_cast<int*>(&val)) {}

  ~Futex() {}

  void wait(INT_T expected) {
    int r = futex(valptr, FUTEX_WAIT,
                  static_cast<int>(expected), NULL, NULL, 0);
    if (r==-1) {
      // There are various legitimate errors that we'll throw an exception for.
      // But there are also these, which are expected in normal operations:
      // EWOULDBLOCK - valptr != expected
      // EINTR - signal or spurious wakeup
      // We might want to return something indicating that one of these conditions
      // had occurred, but it seems that the mutex algorithm doesn't need this.
      switch (errno) {
        case EWOULDBLOCK: return;
        case EINTR:       return;
        default:          throw_ErrnoException("futex(FUTEX_WAIT)");
      }
    }
  }

  bool timed_wait(INT_T expected, const timespec& timeout) {
  // Returns false if timeout reached.
    int r = futex(valptr, FUTEX_WAIT,
                  static_cast<int>(expected), &timeout, NULL, 0);
    if (r==-1) {
      // As above.
      switch (errno) {
        case EWOULDBLOCK: return true;
        case EINTR:       return true;
        case ETIMEDOUT:   return false;
        default:          throw_ErrnoException("futex(FUTEX_WAIT)");
      }
    }
    return true;
  }

  bool timed_wait(INT_T expected, float timeout) {
  // Returns false if timeout reached.
    struct timespec ts;
    float timeout_whole;
    float timeout_frac;
    timeout_frac = modff(timeout, &timeout_whole);
    ts.tv_sec = static_cast<int>(timeout_whole);
    ts.tv_nsec = static_cast<int>(1e9*timeout_frac);
    return timed_wait(expected,ts);
  }

  // Wake up to n waiters; returns the number woken.
  unsigned int wake(int n=1) {
    int r = futex(valptr, FUTEX_WAKE, n, NULL, NULL, 0);
    if (r==-1) {
      throw_ErrnoException("futex(FUTEX_WAIT)");
    }
    return r;
  }
};


};


#endif
#endif

