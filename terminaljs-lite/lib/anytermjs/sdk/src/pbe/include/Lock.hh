// include/Lock.hh
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

#ifndef libpbe_Lock_hh
#define libpbe_Lock_hh

// The file implements a Lock class, which is based on the unique_lock from N2447
// without many of that lock's features.

#include <boost/noncopyable.hpp>


namespace pbe {


template <typename MUTEX_T>
struct Lock: boost::noncopyable {

  typedef MUTEX_T mutex_t;

  mutex_t& m;

  explicit Lock(mutex_t& m_): m(m_) {
    m.lock();
  }

  ~Lock() {
    m.unlock();
  }

  mutex_t* mutex(void) {
    return &m;
  }
};


};

#endif

