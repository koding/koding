// include/ConditionAll.hh
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

#ifndef libpbe_ConditionAll_hh
#define libpbe_ConditionAll_hh

// This file provides a class ConditionAll, which implements a condition variable 
// compatible with N2447's condition_variable_any, except that it provides
// only notify_all() and not notify_one().

// FIXME this should be updated to match Condition.


#include <boost/noncopyable.hpp>

#include "atomic.hh"
#include "Futex.hh"
#include "Unlock.hh"

#include <limits>


namespace pbe {

class ConditionAll: boost::noncopyable {

  uint32_t waiters;
  uint32_t eventcount;
  Futex<uint32_t> fut;

public:
  ConditionAll():
    waiters(0),     // Keep track of the number of waiting threads so that
                    // the notify operations can be no-ops in the case where
                    // there are no waiters.
                    // In an application where there are always waiters, this
                    // is an unnecessary overhead.
    eventcount(0),  // Incremented on each notify_all.  This is needed to
                    // detect any notify_all that occurs between unlocking
                    // the mutex and waiting on the futex.
    fut(eventcount) {}

  ~ConditionAll() {}
  // Note that ~ConditionAll does not wait for any waiters to stop waiting;
  // undefined behaviour results if a ConditionAll is destructed while a thread
  // is still waiting on it.

  void notify_all() {
    if (atomic_read(waiters)==0) {
      return;
    }
    atomic_inc(eventcount);
    uint32_t n_woken = fut.wake(std::numeric_limits<int>::max());
    atomic_dec(waiters,n_woken);
  }

  template <typename LOCK_T>
  void wait(LOCK_T& lock) {
    atomic_inc(waiters);
    uint32_t initial_eventcount = atomic_read(eventcount);
    Unlock<typename LOCK_T::mutex_t> ul(*(lock.mutex()));
                              // Must not throw.  FIXME is this a valid assumption?
                              // If this could throw, we would need to --waiters.
    do {
      // fut.wait can return spuriously e.g. if a signal is handled.
      // We retry in this case, so ConditionAll.wait does not return spuriously.
      fut.wait(initial_eventcount);
    } while (atomic_read(eventcount)==initial_eventcount);
  }

  template <typename LOCK_T, typename Predicate>
  void wait(LOCK_T& lock, Predicate pred) {
    while (!pred()) {
      wait(lock);
    }
  }

  // What type to use for the timeout?  N2447 species that it's 'system_time',
  // which doesn't mean anything to me.  Note that it's an absolute time,
  // in contrast to the relative timeout in Mutex::timed_lock - I'm not sure why.
  // I'll use time_t, though perhaps struct timeval would be more appropriate
  // as it includes a microseconds field.
  template <typename LOCK_T>
  bool timed_wait(LOCK_T& lock, ::time_t abs_time) {
    ::time_t start_time = time(NULL);
    atomic_inc(waiters);
    uint32_t initial_eventcount = atomic_read(eventcount);
    Unlock<typename LOCK_T::mutex_t> ul(*(lock.mutex()));
                              // Must not throw.  FIXME is this a valid assumption?
                              // If this could throw, we would need to --waiters.
    do {
      // fut.timed_wait can return spuriously e.g. if a signal is handled.
      // We retry in this case, so ConditionAll.wait does not return spuriously.
      if (!fut.timed_wait(initial_eventcount, static_cast<float>(abs_time-start_time))) {
        // Timed out.
        atomic_dec(waiters);
        return false;
      }
    } while (atomic_read(eventcount)==initial_eventcount);
    return true;
  }

  template <typename Lock, typename Predicate>
  bool timed_wait(Lock& lock, ::time_t abs_time, Predicate pred) {
    // If the predicate becomes true and the timeout expires at
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

#endif


