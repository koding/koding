// include/string_qsort.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// (C) 2008 Philip Endecott
// This file is distributed under the terms of the Boost Software License v1.0.
// Please see http://www.boost.org/LICENSE_1_0.txt or the accompanying file BOOST_LICENSE.

// string_qsort is a function template that sorts a range of strings using the
// quicksort algorithm, and avoids unnecessary comparisons of string prefixes that
// are already known to be equal while doing so.  The range iterators must be
// random-access and the "strings" they refer to can be any random-access containers.
//
// When the input consists of strings with frequent long common prefixes this can
// give a performance advantage.  However in other cases there is no advantage and
// this implementation's defects then make it slower than std::sort.  Those
// defects are dumb pivot selection, dumb character comparison, no introsort-style
// fallback mode, and general lack of optimisation.


#ifndef libpbe_string_qsort_hh
#define libpbe_string_qsort_hh

#include <algorithm>
#include <string>
#include <vector>
#include <cstring>


namespace pbe {


template <typename ITER>
ITER choose_pivot(ITER begin, ITER end, std::size_t /*equal_prefix_length*/)
{
  // We just choose the middle of the range which gives good results for an
  // already-sorted range.
  // A smart version would do something clever especially when end-begin is large,
  // e.g. choose a set of candidate pivots and use the middle one.
  // (It's a shame we can't just use std::sort's version.)
  // The desire to maximise the prefix length could also be taken into account.
  return begin + (end-begin)/2;
}


template <typename ITER>
bool chars_equal_at_offset(ITER begin, ITER end, std::size_t offset)
{
  // Is the character at [offset] equal for all strings in the range begin to end?

  if (begin->size() <= offset) {
    return false;
  }

  typedef typename ITER::value_type STRING;
  typedef typename STRING::value_type CHAR;
  CHAR c = (*begin)[offset];
  for (ITER i = begin; i != end; ++i) {
    if (i->size() <= offset) {
      return false;
    }
    if ((*i)[offset] != c) {
      return false;
    }
  }
  return true;
}


template <typename STRING>
bool less_with_prefix(const STRING& a, const STRING& b, std::size_t equal_prefix_length)
{
  // Is a < b ?  We know that the fist equal_prefix_length characters of a and b are equal.

  typename STRING::const_iterator ai = a.begin()+equal_prefix_length;
  typename STRING::const_iterator bi = b.begin()+equal_prefix_length;

  // We can make this code a bit faster by avoiding the need to check for end-of-input
  // on both strings on every iteration; instead we determine which is shorter up front
  // and check only that one.

  if (a.size() >= b.size()) {

    while (1) {
      if (bi==b.end()) {
        return false;
      }
      if (*ai != *bi) {
        return *ai < *bi;
      }
      ++ai;
      ++bi;
    }

  } else {

    while (1) {
      if (ai==a.end()) {
        return true;
      }
      if (*ai != *bi) {
        return *ai < *bi;
      }
      ++ai;
      ++bi;
    }

  }
}


bool less_with_prefix(const std::string& a, const std::string& b, std::size_t equal_prefix_length)
{
  // We know that the characters are in contiguous memory for std::string so we can use memcmp().
  if (a.size() >= b.size()) {
    return memcmp(&(a[equal_prefix_length]), &(b[equal_prefix_length]), b.size()-equal_prefix_length) == -1;
  } else {
    return memcmp(&(a[equal_prefix_length]), &(b[equal_prefix_length]), a.size()-equal_prefix_length) != 1;
  }
}

bool less_with_prefix(const std::vector<char>& a, const std::vector<char>& b, std::size_t equal_prefix_length)
{
  // We know that the characters are in contiguous memory for std::vector<char> so we can use memcmp().
  if (a.size() >= b.size()) {
    return memcmp(&(a[equal_prefix_length]), &(b[equal_prefix_length]), b.size()-equal_prefix_length) == -1;
  } else {
    return memcmp(&(a[equal_prefix_length]), &(b[equal_prefix_length]), a.size()-equal_prefix_length) != 1;
  }
}


template <typename ITER>
inline void string_qsort(ITER begin, ITER end, std::size_t equal_prefix_length=0)
{
  if (end-begin < 2) {
    // Nothing to do if there are 0 or 1 elements.
    return;
  }

  if (end-begin == 2) {
    // We can save some effort in this case.
    if (less_with_prefix(*(begin+1), *begin, equal_prefix_length)) {
      std::swap(*(begin+1), *begin);
    }
    return;
  }

  if (end-begin == 3) {
    /// The benefit from this is barely measureable.
    if (less_with_prefix(*(begin+1), *begin, equal_prefix_length)) {
      // BAC CAB CBA
      if (less_with_prefix(*(begin+2), *(begin+1), equal_prefix_length)) {
        // CBA
        std::swap(*begin, *(begin+2));
      } else {
        // BAC CAB
        if (less_with_prefix(*(begin+2), *begin, equal_prefix_length)) {
          // CAB
          std::swap(*begin, *(begin+1));
          std::swap(*(begin+1), *(begin+2));
        } else {
          // BAC
          std::swap(*begin, *(begin+1));
        }
      }
    } else {
      // ABC ACB BCA
      if (less_with_prefix(*(begin+2), *(begin+1), equal_prefix_length)) {
        // ACB BCA
        if (less_with_prefix(*(begin+2), *begin, equal_prefix_length)) {
          // BCA
          std::swap(*begin, *(begin+1));
          std::swap(*begin, *(begin+2));
        } else {
          // ACB
          std::swap(*(begin+1), *(begin+2));
        }
      } else {
        // ABC
      }
    }
    return;
  }

  // Increase the equal prefix length if possible.
  // This is a breadth-first method.  Depth-first is an alternative that
  // would have better locality but could waste effort for some inputs.
  // (Is there a way to do this while partitioning in the previous pass?)
  while (chars_equal_at_offset(begin,end,equal_prefix_length)) {
    ++equal_prefix_length;
  }

  // This is standard quicksort.
  ITER pivot_i = choose_pivot(begin,end,equal_prefix_length);
  std::swap(*pivot_i, *(end-1));
  pivot_i = end-1;
  ITER s = begin;
  for (ITER i = begin; i != pivot_i; ++i) {
    if (less_with_prefix(*i,*pivot_i,equal_prefix_length)) {
      std::swap(*i, *s);
      ++s;
    }
  }
  swap(*s, *pivot_i);

  string_qsort(begin, s, equal_prefix_length);
  string_qsort(s+1, end, equal_prefix_length);
}


};

#endif

