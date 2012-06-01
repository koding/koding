// Locked.hh
// This file is part of libpbe; see http://anyterm.org/
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


// This provides a class template that augments a variable with a mutex, and
// allows access only when the mutex is locked.  Example:
//
//  typedef Locked< vector<int> > x_t;
//  x_t x;
//
//  // We can only modify x via an x_t::writer:
//  x_t::writer xw;
//  // Creating xw locks the mutex.
//  // xw behaves like a pointer to the underlying vector<int>:
//  xw->push_back(123);
//  xw->push_back(321);
//  // The lock is released when xw goes out of scope.
//
//  To read, use an x_t::reader.  It behaves like a const pointer to the
//  underlying data.
//
// The mutex and lock types can be specified with template parameters, but
// they default to the boost versions.
//
// I had hoped to allow conversion-to-reference for the writer and reader, so
// that you could write xw.push_back(123) rather than xw->push_back(123).
// But this didn't work, presumably because I don't really understand how
// implict type conversion is supposed to work.  My attempt is still present,
// commented out.


#ifndef libpbe_Locked_hh
#define libpbe_Locked_hh

#include "Mutex.hh"


namespace pbe {

template <typename T,
          typename MUTEX_T = pbe::Mutex<>,
          typename LOCK_T  = pbe::Lock<MUTEX_T> >
class Locked {

private:
  T data;
  MUTEX_T mutex;

public:
  class writer {
    Locked& locked;
    LOCK_T l;
  public:
    writer(Locked& locked_):
      locked(locked_),
      l(locked.mutex)
    {}
//  operator T&() { return locked.data; }
    T& operator*()  { return locked.data; }
    T* operator->() { return &locked.data; }
  };

  class reader {
    Locked& locked;
    LOCK_T l;
  public:
    reader(Locked& locked_):
      locked(locked_),
      l(locked.mutex)
    {}
//  operator const T&() const { return locked.data; }
    const T& operator*() const  { return locked.data; }
    const T* operator->() const { return &locked.data; }
  };

};


};


#endif
