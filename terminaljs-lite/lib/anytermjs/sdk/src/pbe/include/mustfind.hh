// include/mustfind.hh
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

#ifndef libpbe_mustfind_hh
#define libpbe_mustfind_hh


// pbe::mustfind is an an algorithm like std::find except that it
// throws an exception, pbe::notfound, if it fails to find a match.
// So calling code can rely on the returned iterator pointing to a
// valid element.

// pbe::mustfind_if does the same thing for std::find_if and pbe::mustsearch
// does the same thing for std::search.


#include <algorithm>


namespace pbe {


struct notfound {};


template <typename Iter, typename Comp>
Iter mustfind(Iter first, Iter last, const Comp& val) {
  Iter i = std::find(first,last,val);
  if (i==last) {
    throw notfound();
  }
  return i;
}


template <typename Iter, typename Pred>
Iter mustfind_if(Iter first, Iter last, Pred pred) {
  Iter i = std::find_if(first,last,pred);
  if (i==last) {
    throw notfound();
  }
  return i;
}


template <typename Iter1, typename Iter2>
Iter1 mustsearch(Iter1 first1, Iter1 last1, Iter2 first2, Iter2 last2) {
  Iter1 i = std::search(first1,last1,first2,last2);
  if (i==last1) {
    throw notfound();
  }
  return i;
}


template <typename Iter1, typename Iter2, typename Pred>
Iter1 mustsearch(Iter1 first1, Iter1 last1, Iter2 first2, Iter2 last2, Pred pred) {
  Iter1 i = std::search(first1,last1,first2,last2,pred);
  if (i==last1) {
    throw notfound();
  }
  return i;
}



};


#endif

