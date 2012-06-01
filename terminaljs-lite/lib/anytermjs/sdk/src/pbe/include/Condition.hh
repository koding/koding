// include/Condition.hh
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

#ifndef libpbe_Condition_hh
#define libpbe_Condition_hh

// This file provides a class Condition, which implements a condition variable 
// compatible with N2447's condition_variable[_any?].

// If we have Futex - i.e. if this is Linux - then we implement Condition directly
// on top of Futex.  Otherwise we implement it using pthread_condition.

#include "Futex.hh"
#include "atomic.hh"
#include "HPtime.hh"

#include <boost/noncopyable.hpp>

#include <climits>

#include <time.h>


#if defined(PBE_HAVE_FUTEX) && defined(PBE_HAVE_ATOMICS)

#include "Unlock.hh"


namespace pbe {


class Condition: boost::noncopyable {

  uint32_t waiters;
  uint32_t eventcount;
  Futex<uint32_t> fut;

public:
  Condition():
    waiters(0),     // Keep track of the number of waiting threads so that
                    // the notify operations can be no-ops in the case where
                    // there are no waiters.
    eventcount(0),  // Incremented on each notify_all.  This is needed to
                    // detect any notify_all that occurs between unlocking
                    // the mutex and waiting on the futex.
    fut(eventcount) {}

  ~Condition() {}
  // Note that ~Condition does not wait for any waiters to stop waiting;
  // undefined behaviour results if a Condition is destructed while a thread
  // is still waiting on it.

  void notify_one() {
    if (atomic_read(waiters)==0) {
      return;
    }
    unsigned int n_woken = fut.wake(1);
    if (n_woken==0) {
      notify_all(); // WHY???
      return;
    }
    atomic_dec(waiters,n_woken);
  }

  void notify_all() {
    if (atomic_read(waiters)==0) {
      return;
    }
    atomic_inc(eventcount);
    unsigned int n_woken = fut.wake(INT_MAX);
    atomic_dec(waiters,n_woken);
  }

  template <typename LOCK_T>
  void wait(LOCK_T& lock) {
    atomic_inc(waiters);
    uint32_t initial_eventcount = atomic_read(eventcount);
    Unlock<typename LOCK_T::mutex_t> ul(*lock.mutex());  // Must not throw.
                              // If this could throw, we would need to --waiters.
    do {
      // fut.wait can return spuriously e.g. if a signal is handled.
      // We retry in this case, so Condition.wait does not return spuriously.
      fut.wait(initial_eventcount);
    } while (atomic_read(eventcount)==initial_eventcount);  // NO broken for notify_one
  }

  template <typename LOCK_T, typename Predicate>
  void wait(LOCK_T& lock, Predicate pred) {
    // Note that the following "trivial" implementation is specified by N2447;
    // if notify_one() is called, the thread that is woken may test its condition
    // and sleep again.  There's no guarantee that the notification is delivered
    // to a thread whose condition will evaluate true.  So notify_one() is not
    // useful in combination with predicated wait, unless perhaps all waiters
    // have the same predicate.
    while (!pred()) {
      wait(lock);
    }
  }


  template <typename LOCK_T>
  bool timed_wait(LOCK_T& lock, HPtime abs_time) {
    atomic_inc(waiters);
    uint32_t initial_eventcount = atomic_read(eventcount);
    Unlock<typename LOCK_T::mutex_t> ul(*lock.mutex());  // Must not throw.
                              // If this could throw, we would need to --waiters.
    do {
      // fut.wait can return spuriously e.g. if a signal is handled.
      // We retry in this case, so Condition.wait does not return spuriously.
      HPtime now = HPtime::now();
      if (now>abs_time || !fut.timed_wait(initial_eventcount, abs_time-now)) {
        return false;
      }
    } while (atomic_read(eventcount)==initial_eventcount);  // NO broken for notify_one
    return true;
  }

  template <typename LOCK_T>
  bool timed_wait(LOCK_T& lock, float rel_time) {
    HPtime abs_time = HPtime::now() + rel_time;
    return timed_wait(lock,abs_time);
  }

  template <typename Lock, typename Predicate>
  bool timed_wait(Lock& lock, ::time_t abs_time, Predicate pred) {
    // See above.  If the predicate becomes true and the timeout expires at
    // the same time, we're supposed to return true indicating that the predicate
    // was true.
    while (!pred()) {
      if (!timed_wait(lock,abs_time)) {
        return pred();
      }
    }
    return true;
  }

  // native_handle not provided
};

};

#else


#include <pthread.h>

#include "Exception.hh"


namespace pbe {


class Condition: boost::noncopyable {

  pthread_cond_t cond;

public:
  Condition() {
    int r = pthread_cond_init(&cond, NULL);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_cond_init()",r);
    }
  }

  ~Condition() {
    pthread_cond_destroy(&cond);
  }

  void notify_one() {
    int r = pthread_cond_signal(&cond);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_cond_signal()",r);
    }
  }

  void notify_all() {
    int r = pthread_cond_broadcast(&cond);
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_cond_broadcast()",r);
    }
  }

  template <typename LOCK_T>
  void wait(LOCK_T& lock) {
    int r = pthread_cond_wait(&cond, lock.mutex()->native_handle());
    if (r!=0) {
      pbe::throw_ErrnoException("pthread_cond_wait()",r);
    }
  }

  template <typename LOCK_T, typename Predicate>
  void wait(LOCK_T& lock, Predicate pred) {
    // Note that the following "trivial" implementation is specified by N2447;
    // if notify_one() is called, the thread that is woken may test its condition
    // and sleep again.  There's no guarantee that the notification is delivered
    // to a thread whose condition will evaluate true.  So notify_one() is not
    // useful in combination with predicated wait, unless perhaps all waiters
    // have the same predicate.
    while (!pred()) {
      wait(lock);
    }
  }

  template <typename LOCK_T>
  bool timed_wait(LOCK_T& lock, ::time_t abs_time) {
    timespec ts;
    ts.tv_sec = abs_time;
    ts.tv_nsec = 0;
    int r = pthread_cond_timedwait(&cond, lock.mutex()->native_handle(), &ts);
    switch (r) {
      case 0: return true;
      case ETIMEDOUT: return false;
      default: pbe::throw_ErrnoException("pthread_cond_timedwait()",r);
    }
    // NOT REACHED
    return true;
  }

  template <typename LOCK_T>
  bool timed_wait(LOCK_T& lock, float rel_time) {
    // This limits resolution to whole seconds.
    return timed_wait(lock, static_cast<time_t>(time(NULL)+rel_time));
  }

  template <typename Lock, typename Predicate>
  bool timed_wait(Lock& lock, ::time_t abs_time, Predicate pred) {
    // See above.  If the predicate becomes true and the timeout expires at
    // the same time, we're supposed to return true indicating that the predicate
    // was true.
    while (!pred()) {
      if (!timed_wait(lock,abs_time)) {
        return pred();
      }
    }
    return true;
  }

  pthread_cond_t* native_handle() {
    return &cond;
  }  

};


};


#endif

#endif


