// include/sorted_ptr_vector.hh
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

#ifndef libpbe_sorted_ptr_vector_hh
#define libpbe_sorted_ptr_vector_hh

// Provides a vector of pointers, which is ordered according to one of
// the fields in the pointed-to struct.  It is sorted after construction.

#include <vector>
#include <algorithm>

#include "sort_by_pointee.hh"


namespace pbe {


template <typename T, typename data_member_ptr_t, data_member_ptr_t data_member_ptr>
class sorted_ptr_vector {

  typedef std::vector<T*> vec_t;
  vec_t vec;

public:
  // default ctor is not very useful:
  sorted_ptr_vector() {}
  // default copy ctor is OK
  
  // This is the useful one:
  template <typename iter_t>
  sorted_ptr_vector(iter_t begin, iter_t end):
    vec(begin,end)
  {
    sort_by_pointee(vec.begin(),vec.end(),data_member_ptr);
  }

  typedef typename vec_t::const_iterator const_iterator;

  const_iterator begin() const { return vec.begin(); }
  const_iterator end()   const { return vec.end();   }

};


};


#endif

