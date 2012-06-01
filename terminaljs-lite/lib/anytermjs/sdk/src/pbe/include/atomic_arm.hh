// include/atomic_arm.hh
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

#ifndef libpbe_atomic_arm_hh
#define libpbe_atomic_arm_hh


// This file provides some basic atomic operations for ARM processors
// where the only primitive is swap.


#define PBE_HAVE_ATOMICS


namespace pbe {


// First some asm to do a swap:

template <typename T>
static inline T simple_atomic_swap(volatile T& mem, T newval)
{
  T oldval;
  asm volatile ("swp\t%0, %1, [%2]"
               :"=&r"(oldval)
               :"r"  (newval),
                "r"  (&mem)
               :"memory");
  return oldval;
}

// The other atomic operations are emulated by means of a sentinel value, -1:
// the variable is first swapped with the sentinel, the operation is performed and
// the modified value is written back.  Any thread that wants to read the
// variable must re-try if it reads the sentinel.

template <typename T>
static inline T atomic_read_and_lock(T& var)
{
  do {
    int val = simple_atomic_swap(var,static_cast<T>(-1));
    if (static_cast<int>(val) != -1) {
      return val;
    }
  } while (1);
}


template <typename T>
// T must of course be a type that's atomic on the hardware in use.
// I hope that some sort of error will occur if it isn't.
static inline bool atomic_compare_and_swap(volatile T& var, T expected, T newval) {
  // The return value indicates the result of the compare.
  T oldval = atomic_read_and_lock(var);
  if (oldval==expected) {
    var = newval;
    return true;
  } else {
    var = oldval;
    return false;
  }
}


template <typename T>
static inline T atomic_post_dec(volatile T& var, T amt = 1) {
  T val = atomic_read_and_lock(var);
  var = val - amt;
  return val;
}


template <typename T>
static inline T atomic_pre_inc(volatile T& var, T amt = 1) {
  T val = atomic_read_and_lock(var);
  T newval = val + amt;
  var = newval;
  return newval;
}


template <typename T>
static inline void atomic_inc(volatile T& var, T amt = 1) {
  T val = atomic_read_and_lock(var);
  T newval = val + amt;
  var = newval;
}


template <typename T>
static inline void atomic_dec(volatile T& var, T amt = 1) {
  T val = atomic_read_and_lock(var);
  T newval = val - amt;
  var = newval;
}


template <typename T>
static inline T atomic_swap(volatile T& var, T newval) {
  T oldval = atomic_read_and_lock(var);
  var = newval;
  return oldval;
}


template <typename T>
static inline T atomic_read(volatile T& var) {
  do {
    T val = var;
    if (static_cast<int>(val) != -1) {
      return val;
    }
  } while (1);
};


template <typename T>
static inline void atomic_write(volatile T& var, T newval) {
  atomic_read_and_lock(var);
  var = newval;
};


};

#endif
