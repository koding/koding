// include/Thread.hh
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

#ifndef libpbe_thread_hh
#define libpbe_thread_hh


// This file defines a class Thread, which has a similar interface to 
// Boost.Thread and the proposed std::thread described in N2447, but
// with various extensions including cancellation and priorities.
// It's implemented on top of the POSIX thread primitives, as implemented
// in linux by NPTL; that's included in glibc and sufficiently-new
// versions of uClibc.

#include <boost/noncopyable.hpp>
#include <boost/function.hpp>

#include <sched.h>
#include <pthread.h>
#include <unistd.h>

#include "Exception.hh"


namespace pbe {

class Thread;

namespace this_thread {
  // Operations on the current thread:
//  Thread::id get_id();
  void yield();
  template <typename TimeDuration> void sleep(const TimeDuration& rel_t);
};


// This is a helper used in thread creation, see below:
typedef boost::function<void(void)> thread_fn_t;
// Hmm, maybe this has to be in a .cc file???
static void* start_thread(void* voidstar_fn_ptr) {
  thread_fn_t* fn_ptr = static_cast<thread_fn_t*>(voidstar_fn_ptr);
  thread_fn_t fn = *fn_ptr;
  delete fn_ptr;
  fn();
  return NULL;
}


class Thread: boost::noncopyable {

  // Note that the lifetime of the thread is not coupled to the lifetime of
  // the Thread object; i.e. destroying the Thread object does not terminate
  // the thread.  It's more of a "thread handle" really.


  class pthread_attr_wrapper: boost::noncopyable {
    // The POSIX pthread_attr_t type needs be initialised and destroyed
    // before and after use.  This wrapper makes that automatic.
    ::pthread_attr_t attrs;
  public:
    pthread_attr_wrapper() {
      int r = ::pthread_attr_init(&attrs);
      if (r!=0) {
        // Apparently error code is in r, not errno.  This is the case for many
        // of the pthread_* functions.
        throw_ErrnoException("pthread_attr_init()",r);
      }
    }
    ~pthread_attr_wrapper() {
      ::pthread_attr_destroy(&attrs);
    }
    // Make it possible to use a pthread_attr_wrapper anywhere that a
    // pthread_attr_t* is called for:
    operator ::pthread_attr_t* () {
      return &attrs;
    }
  };


public:
  //typedef pid_t id;  // TODO this should probably be the thread's tid, but pthread_create
                       // doesn't give a way to get this easily.
  typedef ::pthread_t native_handle_type;

  // POSIX defines the scheduling parameters for a thread as a (priority, policy) pair.
  // Higher-priority threads are always run in preference to lower-priority threads,
  // irrespective of scheduling policy.  Scheduling policy determines how equal-priority
  // threads are scheduled, with the two choices SCHED_FIFO and SCHED_RR.  RR, "Round
  // Robin", is somewhat fair in the sense that threads are preempted after a timeslice
  // has elapsed and don't run again until all other threads (at that priority) have
  // had a chance to run.  FIFO, in contrast, runs the same thread until it blocks
  // (e.g. a system call).
  // I'm not totally convinced that Linux necessarily implements all of this: you
  // can find documentation saying that it definitely doesn't, but that may be out of
  // date by now.

  // Neither std::thread not Boost.Threads provides a way to set these parameters,
  // but we do, when the thread is created, using this struct to store the parameters:

  struct scheduling_parameters {
    int priority;
    int policy;
    bool inherit;  // This causes the parameters to be inheritted from the calling thread.

    scheduling_parameters(): inherit(true) {}
    scheduling_parameters(int priority_, int policy_=SCHED_RR):
      priority(priority_), policy(policy_), inherit(false) {}

    // Legitimate values for priority are rather inconveniently defined dynamically
    // and depend on the policy.  There's a guarantee that at least 32 levels exist,
    // but there's no guarantee about any overlap between the ranges for the different
    // policies.  We ignore this: users should assume that the priorities range 0 to 31
    // and that there's an undefined relationship between the policies.

    void set_attrs(::pthread_attr_t* attrs_p) const { // Store these parameters in this
                                                       // pthread_attrs_t
      int r = ::pthread_attr_setinheritsched(attrs_p, inherit ? PTHREAD_INHERIT_SCHED
                                                              : PTHREAD_EXPLICIT_SCHED);
      if (r!=0) {
        throw_ErrnoException("pthread_attr_setinheritsched()",r);
      }
      if (!inherit) {
        r = ::pthread_attr_setschedpolicy(attrs_p, policy);
        if (r!=0) {
          throw_ErrnoException("pthread_attr_setschedpolicy()",r);
        }
        struct ::sched_param p;
        p.sched_priority = priority + ::sched_get_priority_min(policy);
        r = ::pthread_attr_setschedparam(attrs_p, &p);
        if (r!=0) {
          throw_ErrnoException("pthread_attr_setschedparam()",r);
        }
      }
    }
  };


  // The default constructor is supposed to return an object not attached to any
  // thread with an id that compares equal to all detached or joined threads.
  Thread():
    //id(),
    joinable_(false)
  {}


  // This is the main constructor that actually starts a thread.
  // std::thread has this constructor:
  // template <class F, class ...Args> explicit Thread(F f, Args&&... args);
  // The Args&&... stuff is magic C++0x varargs voodoo that we can't use.  We'll
  // use Boost.Function.  Note that there's a thread-safety bug in Boost.Function
  // in 1.34.*; it's fixed in 1.35, but I think that we're OK as gcc provides
  // thread-safe statics by default.
  // We also supply initial scheduling parameters, with a default of inheritting the
  // caller's.  std::thread only allows this via the native_handle hack.
  // We also take a stack size, with a default provided by pthreads (maybe 2 MBytes,
  // or 10 MBytes, or something like that).  There's no way to specify this
  // in std::thread or Boost.Threads.  The kernel will reserve all of this memory,
  // which doesn't matter on a system with lots of swap (though it can make some
  // memory-usage numbers look odd).  On a system with no swap, it's still OK as
  // long as the kernel is happy to over-commit; see /proc/sys/vm/overcommit*.

  explicit Thread(thread_fn_t fn,
                  scheduling_parameters sp = scheduling_parameters(),
                  size_t stacksize=0) {
    pthread_attr_wrapper attrs;
    sp.set_attrs(attrs);
    if (stacksize!=0) {
      int r = ::pthread_attr_setstacksize(attrs,stacksize);
      if (r!=0) {
        throw_ErrnoException("pthread_attr_setstacksize()",r);
      }
    }
    // pthread_create takes a C function pointer, so we can't pass the
    // boost::function to it directly (though we could perhaps specialise
    // this constructor for the simple case where the thread-function is
    // a C function pointer).  Instead we'll use a helper function and pass
    // the boost::function as the arg.  But the pthread_create arg is a
    // void*, and the boost::function is larger than a pointer, and we
    // can't pass a pointer to fn since this function may have terminated
    // and fn gone out of scope before the new thread starts.  Solution:
    // dynamically allocate a copy of fn, and have the new thread delete
    // it.

    thread_fn_t* fn_ptr = new thread_fn_t(fn);

    int r = pthread_create(&pt, attrs, &start_thread, static_cast<void*>(fn_ptr));
    if (r!=0) {
      delete fn_ptr;  // The thread has not been created in any case reporting
                      // an error, right?
      throw_ErrnoException("pthread_create()",r);
    }
    joinable_ = true;
  }


  // Destroying this Thread object does not terminate the thread.
  // It does, however, detach it (see below) if it is still running.
  ~Thread() {
    // We can't unconditionally call detach() as pthread_detach is undefined
    // if called more than once, or if called when join() has been called (I think).
    if (joinable()) {
      detach();
    }
  }

  // std::thread defines C++0x "move" copy constructor and assignment operators.
  // We don't because we don't have the necessary C++0x magic yet.
  // Thread(Thread&&);
  // Thread& operator=(Thread&&);
  // void swap(Thread&&);

  // A thread that has not yet been joined or detached is "joinable".
  // Note that "joinable" doesn't mean that join will return immediately.
  bool joinable() const {
    return joinable_;
  }

  // "joining" with a thread means waiting for it to terminate if it has not
  // yet done so, and then releasing its resources.  It's "wait() for threads".
  void join() {
    int r = ::pthread_join(pt,NULL);
    if (r!=0) {
      throw_ErrnoException("pthread_join()",r);
    }
    joinable_ = false;
  }

  // Note that there is no version of join that takes a timeout.  There's no
  // such functionality provided by POSIX.  If needed, it could be emulated 
  // using a condition variable that's signalled to indicate termination.

  // "detaching" a thread indicates that it will not be "joined"; when it
  // terminates its resources will be released automatically.
  void detach() {
    int r = ::pthread_detach(pt);
    if (r!=0) {
      throw_ErrnoException("pthread_detach()",r);
    }
    joinable_ = false;
  }


  // std::threads doesn't provide any way to cancel a thread.  Boost.Threads
  // does provide a way, but it only provides cancellation points in
  // synchronisation primitives (i.e. lock mutex, wait for condition), not
  // in blocking IO operations.  POSIX does provide cancellation that works
  // for blocking IO, but the POSIX spec doesn't provide for interoperation
  // with C++: destructors and catch-blocks are not executed.  However, the
  // glibc implementation of pthread_cancel() _does_ invoke destructors.
  // But it might not do the right thing with catch blocks; this needs to
  // be understood.  I'm not yet sure if the uClibc NPTL implementation has
  // this C++ integration.
  // Anyway, we provide thread cancellation based on the POSIX primitives.
  // Calling cancel() will ask the thread to cancel and return immediately;
  // it does not wait for the thread to actually terminate.  The thread will
  // start to terminate either immediately, at the next cancellation point,
  // or not at all depending on its current cancellation mode (see 
  // cancellation.hh).  It will then run its destructors and terminate.
  // For a list of functions that must or may be cancellation points, see
  // http://www.opengroup.org/onlinepubs/009695399/functions/xsh_chap02_09.html#tag_02_09_05

  void cancel() {
    int r = ::pthread_cancel(pt);
    if (r!=0) {
      throw_ErrnoException("pthread_cancel()",r);
    }
  }


  //id get_id() const;  // TODO

  native_handle_type native_handle() {
    return pt;
  }

  // This static function indicates the number of processors that the system
  // has. 
  // There are actually two measures, for the total number of processors and
  // the total number of "online" processors, e.g. if the OS can power them
  // up and down dynamically.  This returns the former.
  static unsigned hardware_concurrency() {
    int n = sysconf(_SC_NPROCESSORS_ONLN);
    if (n==-1) {
      throw_ErrnoException("sysconf(_SC_NPROCESSORS_ONLN)");
    }
    return n;
  }

private:
  //id tid;
  pthread_t pt;
  bool joinable_;
};


};

#endif

