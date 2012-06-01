// include/inc_init_vector.hh
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

#ifndef libpbe_inc_init_vector_hh
#define libpbe_inc_init_vector_hh


// pbe::inc_init_vector<T> is like std::vector<T>, except that T must have
// a constructor that takes an integer, and when inc_init_vector<T> is
// constructed with a parameter n it will make n instances of T, passing
// values 0 to n-1 to T's constructor, or when constructed with parameters
// n and m it will make n instances passing values m to m+n-1

#include <vector>


namespace pbe {

template <typename T>
class inc_init_vector: public std::vector<T> {

public:
  inc_init_vector() {}
  inc_init_vector(const inc_init_vector& other): std::vector<T>(other) {}
  inc_init_vector(int n, int m=0) {
    for (int i=m; i<m+n; ++i) {
      push_back(T(i));
    }
  }
};


};


#endif
