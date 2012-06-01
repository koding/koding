// include/Mutex.hh
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

#ifndef libpbe_Mutex_hh
#define libpbe_Mutex_hh


// This file provides class Mutex, which is a model of a non-recursive 
// timed Mutex as defined in N2447.
// It's implemented on top of a user-supplied Futex-like class, defaulting
// to Futex.
// If we don't have Futex (i.e. this isn't Linux), or if we don't have atomic
// operations (i.e. is this an old gcc), the default is a specialisation
// that uses pthread_mutex_t.

#include "atomic.hh"
#include "Lock.hh"
#include "Exception.hh"

#include <boost/noncopyable.hpp>
#include <boost/cstdint.hpp>

#include <sys/time.h>
#include <time.h>


#include "Futex.hh"
#if defined(PBE_HAVE_FUTEX) && defined(PBE_HAVE_ATOMICS)
#define FUTEX_T Futex<>
#else
#include <pthread.h>
#define FUTEX_T pthread_mutex_t
#endif


namespace pbe {

template <typename FUT_T = FUTEX_T>
class Mutex: boost::noncopyable {

#ifdef PBE_HAVE_ATOMICS

  int state;
  FUT_T fut;

public:
  Mutex(): state(0), fut(state) {}

  ~Mutex() {}

  // Lock, waiting if necessary.
  void lock() {
    if (!try_lock()) {
      lock_body();
    }
  }

  // Try to lock, but don't wait if it's not possible.
  // Return indicating whether lock is now held.
  bool try_lock() {
    return atomic_compare_and_swap(state,0,1);
  }

  // Spend up to rel_time trying to lock.
  // Return indicating whether lock is now held.
  // N2447 templates this on the TimeDuration type, but we can't do specialisation
  // of member functions; is that a new C++0x feature?  So we'll use overloading.

  // C++0x will have various time types that can be used here.
  typedef uint32_t microseconds_t;

  bool timed_lock(microseconds_t rel_time) {
    return try_lock() || timed_lock_body(rel_time);
  }

  bool timed_lock(float rel_time) {
    // Careful!  This will fail for durations that overflow microseconds_t, i.e.
    // about an hour.
    // We could postpone the float conversion until after the try_lock().
    return timed_lock(static_cast<microseconds_t>(rel_time*1e6));
  }

  void unlock() {
    if (atomic_post_dec(state) != 1) {
      unlock_body();
    }
  }


  // native_handle not provided.

  // This is not in N2447:
  typedef Lock<Mutex> lock_t;

private:
  void lock_body() {
    while (atomic_swap(state,2) != 0) {
      fut.wait(2);
    }
  }

  bool timed_lock_body(microseconds_t rel_time) {
    ::timeval start;
    // Can gettimeofday() return an error?  The only errors that the joint man
    // page lists apply only to settimeofday(), or to gettimeofday() with the
    // obsolete timezone parameter.
    gettimeofday(&start,NULL);
    while (atomic_swap(state,2) != 0) {
      ::timeval now;
      gettimeofday(&now,NULL);
      microseconds_t elapsed = now.tv_usec - start.tv_usec
                  + 1000000 * (now.tv_sec  - start.tv_sec);
                  // Hmm, this would be faster if we pre-computed the end time
                  // and just did a comparison in here.  But it's not trivial
                  // to add rel_time to start without overlow concerns.
      if (elapsed>rel_time) {
        return false;
      }
      fut.wait(2);
    }
  }

  void unlock_body() {
    atomic_write(state,0);
    fut.wake(1);
  }

#endif

};



#if !(defined(PBE_HAVE_FUTEX) && defined(PBE_HAVE_ATOMICS))

template <>
class Mutex<pthread_mutex_t>: boost::noncopyable {

  pthread_mutex_t mut;

public:
  Mutex() {
    int r = pthread_mutex_init(&mut, NULL);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_mutex_init()",r);
    }
  }

  ~Mutex() {
    pthread_mutex_destroy(&mut);
  }

  // Lock, waiting if necessary.
  void lock() {
    int r = pthread_mutex_lock(&mut);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_mutex_lock()",r);
    }
  }

  // Try to lock, but don't wait if it's not possible.
  // Return indicating whether lock is now held.
  bool try_lock() {
    int r = pthread_mutex_trylock(&mut);
    switch (r) {
      case 0:     return true;
      case EBUSY: return false;
      default:    pbe::throw_ErrnoException("pthread_mutex_trylock()",r);
    }
  }

  // FIXME I'm too lazy to implement timed_lock.

  void unlock() {
    int r = pthread_mutex_unlock(&mut);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_mutex_unlock()",r);
    }
  }


  pthread_mutex_t* native_handle() {
    return &mut;
  }

  // This is not in N2447:
  typedef Lock<Mutex> lock_t;

};

#endif


};

#undef FUTEX_T

#endif

