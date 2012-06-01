// src/Lockable.hh
// This file is part of libpbe; see http://decimail.org
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

#ifndef libpbe_Lockable_hh
#define libpbe_Lockable_hh

#include "Mutex.hh"
#include "Lock.hh"


namespace pbe {

  template <typename T>
  struct Lockable: public T {
    Lockable() {}
    Lockable(const T& t): T(t) {}
    Lockable<T>& operator=(const Lockable<T>& rhs) { return T::operator=(rhs); }
    Lockable<T>& operator=(const T& rhs) { T::operator=(rhs); return *this; }
    typedef pbe::Mutex mutex_t;
    typedef pbe::Lock<mutex_t> scoped_lock_t;
  };


}

#endif

