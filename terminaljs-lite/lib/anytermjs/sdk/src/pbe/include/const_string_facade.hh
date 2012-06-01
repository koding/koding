// include/const_string_facade.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
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

#ifndef pbe_const_string_facade_hh
#define pbe_const_string_facade_hh

#include <algorithm>
#include <iostream>
#include <boost/iterator/reverse_iterator.hpp>
#include <boost/bind.hpp>

#include <string.h>

// const_string_facade makes it simpler to implement a class with
// an interface similar to a const std::string.  The implementation
// simply needs to provide access to pointers to the beginning and
// end of the raw data.
// If the raw data is null-terminated then c_str() will work.
// See ../examples/const_string_facade.cc for example usage.


namespace pbe {


template <typename CHAR>
inline size_t strlen(const CHAR* s) { return std::find(s,s-1,0) - s; }

template<>
inline size_t strlen<char>(const char* s) { return ::strlen(s); }

template<>
inline size_t strlen<unsigned char>(const unsigned char* s) { return ::strlen(reinterpret_cast<const char*>(s)); }

template<>
inline size_t strlen<signed char>(const signed char* s) { return ::strlen(reinterpret_cast<const char*>(s)); }

template <typename ITER, typename CHAR>
inline bool contains(ITER b, ITER e, CHAR c) { return std::find(b,e,c)!=e; }

template <typename ITER, typename CHAR>
inline bool not_contains(ITER b, ITER e, CHAR c) { return std::find(b,e,c)==e; }

template <typename CHAR>
inline int strcmp(CHAR* abeg, CHAR* aend, CHAR* bbeg, CHAR* bend) {
  CHAR* a = abeg;
  CHAR* b = bbeg;
  while (a<aend && b<bend) {
    if (*a < *b) {
      return -1;
    }
    if (*a > *b) {
      return 1;
    }
    ++a;
    ++b;
  }
  if (a<aend) {
    return 1;
  }
  if (b<bend) {
    return -1;
  }
  return 0;
};






template <typename DERIVED, typename CHAR, bool null_terminated>
class const_string_facade {};


template <typename DERIVED, typename CHAR>
class const_string_facade<DERIVED, CHAR, false> {

  DERIVED& derived()             { return *static_cast<DERIVED*>(this); }
  const DERIVED& derived() const { return *static_cast<const DERIVED*>(this); }

public:

  typedef CHAR         value_type;
  typedef CHAR*        pointer;
  typedef CHAR&        reference;
  typedef const CHAR&  const_reference;
  typedef size_t       size_type;
  typedef ptrdiff_t    difference_type;

  static const size_type npos = -1;

  typedef CHAR*        iterator;
  typedef const CHAR*  const_iterator;

  typedef boost::reverse_iterator<iterator>       reverse_iterator;
  typedef boost::reverse_iterator<const_iterator> const_reverse_iterator;

  iterator begin()             { return derived().get_begin(); }
  iterator end()               { return derived().get_end(); }
  const_iterator begin() const { return derived().get_begin(); }
  const_iterator end()   const { return derived().get_end(); }

  reverse_iterator rbegin()             { return reverse_iterator(derived().get_end()); }
  reverse_iterator rend()               { return reverse_iterator(derived().get_begin()); }
  const_reverse_iterator rbegin() const { return const_reverse_iterator(derived().get_end()); }
  const_reverse_iterator rend()   const { return const_reverse_iterator(derived().get_begin()); }

  size_type size()     const { return end() - begin(); }
  size_type length()   const { return end() - begin(); }
  size_type max_size() const { return end() - begin(); }  // ???
  size_type capacity() const { return end() - begin(); }  // ???
  bool empty()         const { return end() == begin(); }

  reference operator[](size_type n)             { return *(begin()+n); }  
  const_reference operator[](size_type n) const { return *(begin()+n); }  

  const CHAR* data() const  { return begin(); }

  size_type copy(CHAR* buf, size_type n, size_type pos=0) const {
    // Is n allowed to be larger than size() ?
    return std::copy(begin()+pos, std::min(end(),begin()+pos+n), buf) - buf;
  }

  template <typename STR>
  size_type find(const STR& s, size_type pos=0) const {
    const_iterator i = std::search(begin()+pos, end(), s.begin(), s.end());
    return (i==end()) ? npos : (i-begin());
  }
  size_type find(const CHAR* s, size_type pos, size_type n) const { 
    const_iterator i = std::search(begin()+pos, end(), s, s+n);
    return (i==end()) ? npos : (i-begin());
  }
  size_type find(const CHAR* s, size_type pos=0) const {
    size_t len = strlen<CHAR>(s);
    return find(s,pos,len);
  }
  size_type find(CHAR c, size_type pos=0) const { 
    const_iterator i = std::find(begin()+pos, end(), c);
    return (i==end()) ? npos : (i-begin());
  }

  template <typename STR>
  size_type rfind(const STR& s, size_type pos=npos) const {
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::search(start, rend(), s.rbegin(), s.rend());
    return (i==rend()) ? npos : (rend()-i-s.size());
  }
  size_type rfind(const CHAR* s, size_type pos, size_type n) const { 
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::search(start, rend(), const_reverse_iterator(s+n), const_reverse_iterator(s));
    return (i==rend()) ? npos : (rend()-i-n);
  }
  size_type rfind(const CHAR* s, size_type pos=npos) const {
    size_t len = strlen<CHAR>(s);
    return rfind(s,pos,len);
  }
  size_type rfind(CHAR c, size_type pos=npos) const { 
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::find(start, rend(), c);
    return (i==rend()) ? npos : (rend()-i-1);
  }

  template <typename STR>
  size_type find_first_of(const STR& s, size_type pos=0) const {
    const_iterator i = std::find_if(begin()+pos, end(), boost::bind(&contains<STR::const_iterator,CHAR>,s.begin(),s.end(),_1));
    return (i==end()) ? npos : (i-begin());
  }
  size_type find_first_of(const CHAR* s, size_type pos, size_type n) const {
    const_iterator i = std::find_if(begin()+pos, end(), boost::bind(&contains<const CHAR*,CHAR>,s,s+n,_1));
    return (i==end()) ? npos : (i-begin());
  }
  size_type find_first_of(const CHAR* s, size_type pos=0) const {
    size_t len = strlen<CHAR>(s);
    return find_first_of(s,pos,len);
  }
  size_type find_first_of(CHAR c, size_type pos=0) const {
    return find(c,pos);
  }

  template <typename STR>
  size_type find_first_not_of(const STR& s, size_type pos=0) const {
    const_iterator i = std::find_if(begin()+pos, end(), boost::bind(&not_contains<STR::const_iterator,CHAR>,s.begin(),s.end(),_1));
    return (i==end()) ? npos : (i-begin());
  }
  size_type find_first_not_of(const CHAR* s, size_type pos, size_type n) const {
    const_iterator i = std::find_if(begin()+pos, end(), boost::bind(&not_contains<const CHAR*,CHAR>,s,s+n,_1));
    return (i==end()) ? npos : (i-begin());
  }
  size_type find_first_not_of(const CHAR* s, size_type pos=0) const {
    size_t len = strlen<CHAR>(s);
    return find_first_not_of(s,pos,len);
  }
  size_type find_first_not_of(CHAR c, size_type pos=0) const {
    return find_first_not_of(&c, pos, 1);  // FIXME should use find_if
  }

  template <typename STR>
  size_type find_last_of(const STR& s, size_type pos=npos) const {
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::find_if(start, rend(), boost::bind(&contains<STR::const_iterator,CHAR>,s.begin(),s.end(),_1));
    return (i==rend()) ? npos : (rend()-i-1);
  }
  size_type find_last_of(const CHAR* s, size_type pos, size_type n) const {
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::find_if(start, rend(), boost::bind(&contains<const CHAR*,CHAR>,s,s+n,_1));
    return (i==rend()) ? npos : (rend()-i-1);
  }
  size_type find_last_of(const CHAR* s, size_type pos=npos) const {
    size_t len = strlen<CHAR>(s);
    return find_last_of(s,pos,len);
  }
  size_type find_last_of(CHAR c, size_type pos=npos) const {
    return rfind(c,pos);
  }

  template <typename STR>
  size_type find_last_not_of(const STR& s, size_type pos=npos) const {
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::find_if(start, rend(), boost::bind(&not_contains<STR::const_iterator,CHAR>,s.begin(),s.end(),_1));
    return (i==rend()) ? npos : (rend()-i-1);
  }
  size_type find_last_not_of(const CHAR* s, size_type pos, size_type n) const {
    const_reverse_iterator start = rend() - std::min(pos,size());
    const_reverse_iterator i = std::find_if(start, rend(), boost::bind(&not_contains<const CHAR*,CHAR>,s,s+n,_1));
    return (i==rend()) ? npos : (rend()-i-1);
  }
  size_type find_last_not_of(const CHAR* s, size_type pos=npos) const {
    size_t len = strlen<CHAR>(s);
    return find_last_not_of(s,pos,len);
  }
  size_type find_last_not_of(CHAR c, size_type pos=npos) const {
    return find_last_not_of(&c, pos, 1);  // FIXME should use find_if
  }

  std::basic_string<CHAR> substr(size_type pos=0, size_type n=npos) const {
    return std::basic_string<CHAR>(begin()+pos,begin()+std::min(n,size()));
  }

  template <typename STR>
  int compare(const STR& s) const {
    return strcmp(begin(), end(), s.begin(), s.end());
  }
  template <typename STR>
  int compare(size_type pos, size_type n, const STR& s) const {
    return strcmp(begin()+pos, begin()+pos+n, s.begin(), s.end());
  }
  template <typename STR>
  int compare(size_type pos, size_type n, const STR& s, size_type pos1, size_type n1) const {
    return strcmp(begin()+pos, begin()+pos+n, s.begin()+pos1, s.begin()+pos1+n1);
  }
  int compare(const CHAR* s) const {
    return strcmp(begin(), end, s, s+strlen<CHAR>(s));
  }
  int compare(size_type pos, size_type n, const CHAR* s, size_type len=npos) const {
    return strcmp(begin()+pos, begin()+pos+n, s, s+std::min(len,strlen<CHAR>(s)));  // traits::length???
  }

};


#if 0
template <typename CHAR>
class const_string_facade<CHAR,true>: public const_string_facade<CHAR,false> {
public:
  const CHAR* c_str() const { return begin(); }
};
#endif



template <typename CHAR, typename DERIVED1, bool null_terminated_1, typename DERIVED2, bool null_terminated_2>
inline bool operator==(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                       const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s1.compare(s2) == 0;
}

template <typename CHAR, typename DERIVED2, bool null_terminated_2>
inline bool operator==(const CHAR* s1,
                       const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s2.compare(s1) == 0;
}

template <typename CHAR, typename DERIVED1, bool null_terminated_1>
inline bool operator==(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                       const CHAR* s2) {
  return s1.compare(s2) == 0;
}


template <typename CHAR, typename DERIVED1, bool null_terminated_1, typename DERIVED2, bool null_terminated_2>
inline bool operator!=(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                       const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s1.compare(s2) != 0;
}

template <typename CHAR, typename DERIVED2, bool null_terminated_2>
inline bool operator!=(const CHAR* s1,
                       const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s2.compare(s1) != 0;
}

template <typename CHAR, typename DERIVED1, bool null_terminated_1>
inline bool operator!=(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                       const CHAR* s2) {
  return s1.compare(s2) != 0;
}


template <typename CHAR, typename DERIVED1, bool null_terminated_1, typename DERIVED2, bool null_terminated_2>
inline bool operator<(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                      const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s1.compare(s2) < 0;
}

template <typename CHAR, typename DERIVED2, bool null_terminated_2>
inline bool operator<(const CHAR* s1,
                      const const_string_facade<DERIVED2,CHAR,null_terminated_2>& s2) {
  return s2.compare(s1) < 0;
}

template <typename CHAR, typename DERIVED1, bool null_terminated_1>
inline bool operator<(const const_string_facade<DERIVED1,CHAR,null_terminated_1>& s1,
                      const CHAR* s2) {
  return s1.compare(s2) < 0;
}


template <typename CHAR, typename TRAITS, typename DERIVED, bool null_terminated>
inline std::basic_ostream<CHAR, TRAITS>& operator<<(std::basic_ostream<CHAR, TRAITS>& os,
                                                    const const_string_facade<DERIVED, CHAR, null_terminated>& s) {
  std::ostream_iterator<CHAR> osi(os);
  copy(s.begin(),s.end(),osi);  // something about os.width() ???
  return os;
}


};

#endif

