// AtomicCounter.hh
// This file is part of libpbe; see http://decimail.org/
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

#ifndef libpbe_AtomicCounter_hh
#define libpbe_AtomicCounter_hh


// Atomic (i.e. thread-safe) counter.  Uses the gcc atomic builtins, except on ARM
// where they are not available.  On ARM it uses a swap instruction, using -1 as a sentinel
// value (and has one fewer useful bits as a consequence; code should allow for the counter 
// wrapping after 31 or 32 bits).  It normally spins if it can't get the lock, but you can define 
// YIELD_WHEN_LOCKED to make it yield in that case.  Contention should be extremely rare.

// FIXME this should use atomic.hh.  It should also test whether the gcc builtins are
// available.


#include <stdint.h>


#if defined(__arm__) && defined(YIELD_WHEN_LOCKED)
#include <sched.h>
#endif


namespace pbe {


#ifdef __arm__

static inline int32_t arm_atomic_read_and_lock(int32_t& mem)
{
  int32_t val;
  do {
    // Equivalent to:
    //   val = mem;
    //   mem = -1;
    asm volatile ("swp\t%0, %1, [%2]"
                 :"=&r"(val)
                 :"r"  (-1),
                  "r"  (&mem)
                 :"memory");
    if (val != -1) {
      break;
    }
#ifdef YIELD_WHEN_LOCKED
    sched_yield();
#endif
  } while (1);
  return val;
}

static inline int32_t arm_atomic_inc(int32_t& mem, int32_t inc)
{
  return mem = (arm_atomic_read_and_lock(mem)+inc) & 0x7fffffff;
}

static inline int32_t arm_atomic_inc_pre(int32_t& mem, int32_t inc)
{
  int32_t r = arm_atomic_read_and_lock(mem);
  mem = (r+inc) & 0x7fffffff;
  return r;
}

#endif



class AtomicCounter {

  int c;

public:
  AtomicCounter():
    c(0)
  {}

  AtomicCounter(int n):
    c(n)
  {}

  int operator++() {  //  ++n
#ifdef __arm__
  return arm_atomic_inc(c, 1);
#else
  return __sync_add_and_fetch(&c, 1);
#endif
  }

  int operator++(int) { // n++
#ifdef __arm__
  return arm_atomic_inc_pre(c, 1);
#else
  return __sync_fetch_and_add(&c, 1);
#endif
  }

  int operator--() {  //  --n
#ifdef __arm__
  return arm_atomic_inc(c, -1);
#else
  return __sync_add_and_fetch(&c, -1);
#endif
  }

  int operator--(int) { // n--
#ifdef __arm__
  return arm_atomic_inc_pre(c, -1);
#else
  return __sync_fetch_and_add(&c, -1);
#endif
  }
};

};

#endif
