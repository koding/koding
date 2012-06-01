// include/sort_by_pointee.hh
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

#ifndef libpbe_sort_by_pointee_hh
#define libpbe_sort_by_pointee_hh

// Provides a function sort_by_pointee, which is like std::sort except that it
// takes a pointer to member to indicate which field of a struct it should
// use for sorting.
// Typical usage:
// struct T { int a; ..... };
// std::container<T*> c;
// sort_by_pointee(c.begin(),c.end(),&T::a);


#include <algorithm>


namespace pbe {

template <typename ptr_t, typename data_member_ptr_t>
struct compare_ptr_data_member {
  data_member_ptr_t data_member_ptr;
  compare_ptr_data_member(data_member_ptr_t data_member_ptr_):
    data_member_ptr(data_member_ptr_)
  {}
  bool operator()(ptr_t a, ptr_t b)
  {
    return a->*data_member_ptr < b->*data_member_ptr;
  }
};

template <typename iter_t, typename data_member_ptr_t>
void sort_by_pointee(iter_t begin, iter_t end, data_member_ptr_t data_member_ptr) {
  std::sort(begin,end,
            compare_ptr_data_member<typename iter_t::value_type,
                                    data_member_ptr_t> (data_member_ptr));
}


};


#endif

