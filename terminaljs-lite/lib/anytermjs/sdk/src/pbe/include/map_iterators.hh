// include/map_iterators.hh
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

#ifndef libpbe_map_iterators_hh
#define libpbe_map_iterators_hh

// Provides map_key_iterator and map_value_iterator, which adapt a
// std::map::iterator to iterate over only the keys or values respectively.

#include <boost/iterator/transform_iterator.hpp>
#include <ext/functional>


namespace pbe {

template <typename iter_t>
struct map_key_iterator:
  public boost::transform_iterator< __gnu_cxx::select1st<typename iter_t::value_type>,
                                    iter_t >
{
  map_key_iterator() {}
  map_key_iterator(iter_t i):
    boost::transform_iterator< __gnu_cxx::select1st<typename iter_t::value_type>, iter_t >(i)
  {}
};

template <typename iter_t>
static map_key_iterator<iter_t> make_map_key_iterator(const iter_t& i) {
  return map_key_iterator<iter_t>(i);
}



template <typename iter_t>
struct map_value_iterator:
  public boost::transform_iterator< __gnu_cxx::select2nd<typename iter_t::value_type>,
                                    iter_t >
{
  map_value_iterator() {}
  map_value_iterator(iter_t i):
    boost::transform_iterator< __gnu_cxx::select2nd<typename iter_t::value_type>, iter_t >(i)
  {}
};

template <typename iter_t>
static map_value_iterator<iter_t> make_map_value_iterator(const iter_t& i) {
  return map_value_iterator<iter_t>(i);
}


};

#endif

