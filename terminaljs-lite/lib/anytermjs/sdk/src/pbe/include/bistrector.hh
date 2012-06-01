// include/bistrector.hh
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

#ifndef libpbe_bistrector_hh
#define libpbe_bistrector_hh

// bistrector: bidirectionally-stretchy-vector
// -------------------------------------------
//
// Provides a vector which stretches when new elements are accessed
// using operator[].  It stretches in both directions, i.e. only enough
// space for elements between the minimum and maximem indices is
// allocated.  In contrast, a strector allocates space between 0 and
// the maximum index.
//
// This is actually implemented using a pair of strectors, one for elements
// above the first one added and a reversed one for those below it.  A 
// consequence is that if elements are erased the bistrector cannot shrink 
// beyond the first element added.  In fact, erasing elements in general
// is problematic because of this and is not implemented, except for clear().
//
// The rules for invalidation etc. are the same as for strector.
//
// An additional optional constructor parameter allows you to specify a value
// used for new elements when the vector is resized during operator[] and
// when a beyond-the-end element is read as above.


#include "strector.hh"

#include <boost/iterator/iterator_facade.hpp>


namespace pbe {


template < typename T, typename ALLOC=std::allocator<T> >
class bistrector: public std::vector<T,ALLOC> {
  typedef strector<T,ALLOC> strector_t;
  strector_t bottom;
  strector_t top;
  size_t mid_index;

public:
  typedef T value_type;
  typedef T* pointer;
  typedef T& reference;
  typedef const T& const_reference;
  typedef size_t size_type;
  typedef ssize_t difference_type;
  

  // Most of the vector ctors don't make much sense and aren't implemented.

  bistrector(): mid_index(0) {}
  explicit bistrector(const T& default_t): bottom(default_t), top(default_t), mid_index(0) {}
  bistrector(const bistrector& other): bottom(other.bottom), top(other.top), mid_index(other.mid_index) {}

  template <typename iter_t>
  void advance_iterator(iter_t& i, bool& top_half, size_t n) {
    if (n>0) {
      if (top_half) {
        i += n;
      } else if (i-bottom.begin() >= n) {
        i -= n;
      } else {
        i = top.begin() + (i-bottom.begin()) + (n-1);
        top_half = true;
      }
    } else {
      if (!top_half) {
        i -= n;
      } else if (i-top.begin() >= -n) {
        i += n;
      } else {
        i = bottom.begin() + (i-top.begin()) + (-n-1);
        top_half = false;
      }
    }
  }


  class iterator:
    public boost::iterator_facade< iterator, T, std::random_access_iterator_tag > {

    friend class boost::iterator_core_access;
    friend class bistrector;    

    const bistrector& b;
    bool top_half;
    typename strector_t::iterator i;

    iterator(const bistrector& b_, bool top_half_, typename strector_t::iterator i_):
      b(b_), top_half(top_half_), i(i_)
    {}

    T& dereference() {
      return *i;
    }

    bool equal(const iterator& other) {
      return i == other.i;
    }

    void advance(size_t n) {
      b.advance_iterator(i,top_half,n);
    }
        
    void increment() {
      advance(1);
    }

    void decrement() {
      advance(-1);
    }

  };


  class const_iterator:
    public boost::iterator_facade< const_iterator, T, std::random_access_iterator_tag, const T& > {

    friend class boost::iterator_core_access;
    friend class bistrector;    

    const bistrector& b;
    bool top_half;
    typename strector_t::const_iterator i;

    const_iterator(const bistrector& b_, bool top_half_, typename strector_t::const_iterator i_):
      b(b_), top_half(top_half_), i(i_)
    {}

    const T& dereference() {
      return *i;
    }

    bool equal(const const_iterator& other) {
      return i == other.i;
    }

    void advance(size_t n) {
      bistrector::advance_iterator(i,top_half,n);
    }
        
    void increment() {
      advance(1);
    }

    void decrement() {
      advance(-1);
    }

  };


  iterator begin() {
    if (bottom.empty()) {
      return iterator(*this,true,top.begin());
    } else {
      return iterator(*this,false,bottom.end()-1);
    }
  }

  iterator end() {
    return iterator(*this,true,top.end());
  }

  const_iterator begin() const {
    if (bottom.empty()) {
      return const_iterator(*this,true,top.begin());
    } else {
      return const_iterator(*this,false,bottom.end()-1);
    }
  }

  const_iterator end() const {
    return const_iterator(*this,true,top.end());
  }

  size_type size() const {
    return top.size() + bottom.size();
  }

  size_type max_size() const {
    return top.max_size() + bottom.max_size();
  }

  bool empty() const {
    return top.empty() && bottom.empty();
  }

  reference operator[](size_type n) {
    if (top.empty() && bottom.empty()) {
      mid_index = n;
    }
    if (n>=mid_index) {
      return top[n-mid_index];
    } else {
      return bottom[mid_index-n-1];
    }
  }

  const_reference operator[](size_type n) const {
    if (n>=mid_index) {
      return top[n-mid_index];
    } else {
      return bottom[mid_index-n-1];
    }
  }

  reference front() {
    if (bottom.empty()) {
      return top.front();
    } else {
      return bottom.back();
    }
  }

  const_reference front() const {
    if (bottom.empty()) {
      return top.front();
    } else {
      return bottom.back();
    }
  }

  reference back() {
    if (top.empty()) {
      return bottom.front();
    } else {
      return top.back();
    }
  }

  const_reference back() const {
    if (top.empty()) {
      return bottom.front();
    } else {
      return top.back();
    }
  }

  void push_back(const T& t) {
    top.push_back(t);
  }

  void clear() {
    top.clear();
    bottom.clear();
  }
};


};


#endif

