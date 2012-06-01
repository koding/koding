// include/init_array.hh
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

// This work is based on Boost.Array, which is:
// (C) Copyright Nicolai M. Josuttis 2001.
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)


#ifndef libpbe_init_array_hh
#define libpbe_init_array_hh

// pbe::init_array<T,N> is like boost::array<T,N>, except that it provides
// a constructor that takes a T and copy-constructs each of its elements
// using it.

#include <boost/assert.hpp>

#include <stdexcept>


namespace pbe {

template <typename T, int N>
class init_array {

  char mem[sizeof(T)*N]; // worry about alignment

public:

  // Unlike Boost.Array, elems is a function:
  T* elems() { return reinterpret_cast<T*>(&mem); }
  const T* elems() const { return reinterpret_cast<T*>(&mem); }

  init_array() {
    int i;
    try {
      for (i=0; i<N; ++i) {
        new(elems()+i) T();
      }
    }
    catch (...) {
      --i;
      for (; i>0; --i) {
        (elems()+i) -> ~T();
      }
      throw;
    }
  }

  init_array(T t) {
    int i;
    try {
      for (i=0; i<N; ++i) {
        new(elems()+i) T(t);
      }
    }
    catch (...) {
      --i;
      for (; i>0; --i) {
        (elems()+i) -> ~T();
      }
      throw;
    }
  }

  ~init_array() {
    for (int i=N-1; i>=0; --i) {
      (elems()+i) -> ~T();
    }
  }

  // type definitions
  typedef T              value_type;
  typedef T*             iterator;
  typedef const T*       const_iterator;
  typedef T&             reference;
  typedef const T&       const_reference;
  typedef std::size_t    size_type;
  typedef std::ptrdiff_t difference_type;
    
  // iterator support
  iterator begin() { return elems(); }
  const_iterator begin() const { return elems(); }
  iterator end() { return elems()+N; }
  const_iterator end() const { return elems()+N; }

  // reverse iterator support
  typedef std::reverse_iterator<iterator> reverse_iterator;
  typedef std::reverse_iterator<const_iterator> const_reverse_iterator;

  reverse_iterator rbegin() { return reverse_iterator(end()); }
  const_reverse_iterator rbegin() const {
    return const_reverse_iterator(end());
  }
  reverse_iterator rend() { return reverse_iterator(begin()); }
  const_reverse_iterator rend() const {
    return const_reverse_iterator(begin());
  }

  // operator[]
  reference operator[](size_type i) 
  { 
    BOOST_ASSERT( i < N && "out of range" ); 
    return elems()[i];
  }
  
  const_reference operator[](size_type i) const 
  {     
    BOOST_ASSERT( i < N && "out of range" ); 
    return elems()[i]; 
  }

  // at() with range check
  reference at(size_type i) { rangecheck(i); return elems()[i]; }
  const_reference at(size_type i) const { rangecheck(i); return elems()[i]; }
    
  // front() and back()
  reference front() 
  { 
    return elems()[0]; 
  }
  
  const_reference front() const 
  {
    return elems()[0];
  }
  
  reference back() 
  { 
    return elems()[N-1]; 
  }
  
  const_reference back() const 
  { 
    return elems()[N-1]; 
  }

  // size is constant
  static size_type size() { return N; }
  static bool empty() { return false; }
  static size_type max_size() { return N; }
  enum { static_size = N };

  // swap (note: linear complexity)
  void swap (init_array<T,N>& y) {
    std::swap_ranges(begin(),end(),y.begin());
  }

  // direct access to data (read-only)
  const T* data() const { return elems(); }

  // use array as C array (direct read/write access to data)
  T* c_array() { return elems(); }

  // assignment with type conversion
  template <typename T2>
  init_array<T,N>& operator= (const init_array<T2,N>& rhs) {
    std::copy(rhs.begin(),rhs.end(), begin());
    return *this;
  }

  // assign one value to all elements
  void assign (const T& value)
  {
    std::fill_n(begin(),size(),value);
  }

  // check range (may be private because it is static)
  static void rangecheck (size_type i) {
    if (i >= size()) { 
      throw std::range_error("init_array<>: index out of range");
    }
  }

};


// comparisons
template<class T, std::size_t N>
bool operator== (const init_array<T,N>& x, const init_array<T,N>& y) {
  return std::equal(x.begin(), x.end(), y.begin());
}
template<class T, std::size_t N>
bool operator< (const init_array<T,N>& x, const init_array<T,N>& y) {
  return std::lexicographical_compare(x.begin(),x.end(),y.begin(),y.end());
}
template<class T, std::size_t N>
bool operator!= (const init_array<T,N>& x, const init_array<T,N>& y) {
  return !(x==y);
}
template<class T, std::size_t N>
bool operator> (const init_array<T,N>& x, const init_array<T,N>& y) {
  return y<x;
}
template<class T, std::size_t N>
bool operator<= (const init_array<T,N>& x, const init_array<T,N>& y) {
    return !(y<x);
}
template<class T, std::size_t N>
bool operator>= (const init_array<T,N>& x, const init_array<T,N>& y) {
        return !(x<y);
}

// global swap()
template<class T, std::size_t N>
inline void swap (init_array<T,N>& x, init_array<T,N>& y) {
    x.swap(y);
}


};


#endif
