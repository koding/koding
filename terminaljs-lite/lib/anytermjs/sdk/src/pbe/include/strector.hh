// include/strector.hh
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

#ifndef libpbe_strector_hh
#define libpbe_strector_hh

// strector: stretchy-vector
// -------------------------
//
// Provides a vector which stretches when new elements are accessed
// using operator[].
//
// Since the stretch may cause the vector to re-allocate, operator[]
// on a mutable strector invalidates iterators, references and pointers 
// to its elements unless the index is less than capacity().
//
// What should operator[] do for a const strector when you access a
// beyond-the-end element?  It can't stretch the vector.  It could be
// undefined (like vector).  It could throw.  It could return a default
// T by value - but then it would have to return by value in all cases.
// The option that I've chosen is to return a const reference to a static
// T.  This is broken if you try to compare addresses of elements.  It
// is also broken if you expected the reference to change when you wrote
// to that element via a mutable reference to the strector, but that would
// be broken anyway unless size() < index < capacity() due to the 
// iterator-invalidation rules.  The use of a static may also have 
// thread-safety problems.
//
// An additional optional constructor parameter allows you to specify a value
// used for new elements when the vector is resized during operator[] and
// when a beyond-the-end element is read as above.


#include <vector>


namespace pbe {


template < typename T, typename ALLOC=std::allocator<T> >
class strector: public std::vector<T,ALLOC> {
  typedef std::vector<T,ALLOC> base_t;
  const T default_t;

public:
  // Same ctors as std::vector:
  strector() {}
  strector(typename base_t::size_type n): base_t(n) {}
  strector(typename base_t::size_type n, const T& t): base_t(n,t), default_t(t) {}
  // The copy-ctor takes a base_t, so we can copy from another strector or
  // from a compatible std::vector:
  strector(const base_t& other): base_t(other) {}
  template <typename iter>
  strector(iter first, iter last): base_t(first,last) {}

  // Additional ctor to specify default_t:
  explicit strector(const T& default_t_): default_t(default_t_) {}
  
  typename base_t::reference operator[](typename base_t::size_type n) {
    if (n>=base_t::size()) {
      base_t::resize(n+1,default_t);
    }
    return base_t::operator[](n);
  }
  typename base_t::const_reference operator[](typename base_t::size_type n) const {
    if (n>=base_t::size()) {
      return default_t;
    }
    return base_t::operator[](n);
  }
};


};


#endif

