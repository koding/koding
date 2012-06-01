// include/atomic.hh
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

#ifndef libpbe_atomic_hh
#define libpbe_atomic_hh


// This file provides some basic atomic operations using the gcc builtins. 
// It doesn't attempt to provide an N2427-compatiable interface.
// Memory ordering sematics are those provided by the gcc builtins,
// which basically means that they all provide full memory barriers (I think).

// We have a special version for ARM:

#ifdef __arm__
#include "atomic_arm.hh"
#else

// gcc provides __sync atomic primatives from version 4.1.  However,
// they didn't bother to add the feature-test-macros until version 4.2 or 4.3.
// Ideally we would ignore the gcc versions that have the primitives
// but don't tell us about them, but unfortunately that covers a few systems
// that we might be interested in.  So for the time being we'll fake it:

#if __GNUC__ == 4 && __GNUC_MINOR__ == 1
// Maybe need to check for 4.2 too.
// This assumes that all types <= 32 bits are atomic, which is a good
// bet but not 100% certain.
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4
#endif


#if defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_1) || defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2) \
 || defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4)

#define PBE_HAVE_ATOMICS

namespace pbe {

// The N2427 proposed CAS is:
// if ( *object == *expected )
//     *object = desired;
// else
//     *expected = *object;
// The boolean result of the comparison is returned.
// Note that *expected is updated if the comparison fails.  This seems 
// odd to me; it isn't what the gcc builtin does.  I'm going to provide 
// something closer to gcc.

template <typename T>
// T must of course be a type that's atomic on the hardware in use.
// I hope that some sort of error will occur if it isn't.
bool atomic_compare_and_swap(volatile T& var, T expected, T newval) {
  // The return value indicates the result of the compare.
  return __sync_bool_compare_and_swap(&var, expected, newval);
}


template <typename T>
T atomic_post_dec(volatile T& var, T amt = 1) {
  return __sync_fetch_and_sub(&var, amt);
}


template <typename T>
T atomic_pre_inc(volatile T& var, T amt = 1) {
  return __sync_add_and_fetch(&var, amt);
}


template <typename T>
void atomic_inc(volatile T& var, T amt = 1) {
  __sync_fetch_and_add(&var, amt);
}


template <typename T>
void atomic_dec(volatile T& var, T amt = 1) {
  __sync_fetch_and_sub(&var, amt);
}


template <typename T>
T atomic_swap(volatile T& var, T newval) {
  return __sync_lock_test_and_set(&var,newval);  // misnamed
}


template <typename T>
T atomic_read(volatile T& var) {
  return var;
};


template <typename T>
void atomic_write(volatile T& var, T newval) {
  var = newval;
};


};

#endif

#endif
#endif

