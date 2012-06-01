// src/safe_int.hh
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


// safe_int<N>: provide an N-bit signed integer (N excludes the sign bit) with overflow 
// checking.  An exception is thrown if the value overflows.

// The implementation uses Boost.Integer to supply an integer with at least one more bit 
// than we need.  This extra guard bit is tested to detect overflow.
// This approach is reasonably efficient, except in the case where the need for the extra 
// bit means that we have to use a larger underlying value; for example, safe_int<31> needs 
// an int64_t.  There is another approach that could work in that case, which is to compare 
// the operands before performing the operation; that could be added as a specialisation of 
// this template for safe_int<31>, safe_int<15> and safe_int<7>.

// One of the better resources describing this subject is:
// http://msdn2.microsoft.com/en-us/library/ms972705.aspx


#ifndef libpbe_safe_int_hh
#define libpbe_safe_int_hh

#include "./integer.hpp"
#include <boost/operators.hpp>

namespace pbe {

template <int NBITS>  // NBITS excludes the sign bit
class safe_int:
  boost::operators<safe_int<NBITS> >
{
public:
  struct overflow: public std::exception {
    const char* what() const throw() { return "safe_int overflow"; }
  };

private:
  typedef typename boost::int_t<NBITS+2>::least val_t;
  val_t val;

  void check() {
    // If guard bits != sign bit, value has overflowed.
    val_t x = val>>NBITS;
    if (x==0 || x==-1) {
      return;
    }
    throw overflow();
  }

public:
  safe_int() {}
  safe_int(const safe_int& x): val(x.val) {}

  // This can convert from integer or other safe_int types.
  // It would be good if we could do a non-checking version when X_T is guaranteed to be 
  // smaller than NBITS.  Is there any template-magic that can do that?  (enable_if?)
  template <typename X_T>
  safe_int(X_T x): val(static_cast<val_t>(x)) { check(); }

  // Implicitly convert to val_t.  (Is this a safe thing to do?)
  operator val_t() { return val; }

  // These don't need any checking:
  bool operator<(const safe_int& x) const  { return val<x.val; }
  bool operator==(const safe_int& x) const { return val==x.val; }
  safe_int& operator|=(const safe_int& x)     { val|=x.val; return *this; }
  safe_int& operator&=(const safe_int& x)     { val&=x.val; return *this; }
  safe_int& operator^=(const safe_int& x)     { val^=x.val; return *this; }
  safe_int& operator>>=(const safe_int& x)    { val>>=x.val; return *this; }

  // These can be checked using the guard bit:
  safe_int& operator+=(const safe_int& x)     { val+=x.val; check(); return *this; }
  safe_int& operator-=(const safe_int& x)     { val-=x.val; check(); return *this; }

  // These need more complex checking:

  // This only works when val_t is <= int32_t.
  safe_int& operator*=(const safe_int& x) {
    // Do a multiplication that is certain to have enough bits for the result:
    typedef typename boost::int_t<2*NBITS+1>::least twice_val_t;
    twice_val_t tw = static_cast<twice_val_t>(val) * static_cast<twice_val_t>(x.val);
    // Overflow if any too-significant bits are set:
    twice_val_t r = tw >> NBITS;
    if (r!=0 && r!=-1) {
      throw overflow();
    }
    val = static_cast<val_t>(tw);
    return *this;
  }

  // The only case where division can overflow is -MAX/-1.
  // We could also detect division by zero here if we wanted to.
  safe_int& operator/=(const safe_int& x) {
    if (x.val==-1 && val==(1<<NBITS)) {
      throw overflow();
    }
    val/=x.val;
    return *this;
  }

  // I honestly have no idea what this should do.  In fact I don't know what % does for 
  // negative operands.

  safe_int& operator%=(const safe_int& x) { val%=x.val; return *this; }


  // It's OK to shift left by x bits if the most significant x bits are equal to the sign 
  // bit.  Check by shifting right so that all the other bits are lost.

  safe_int& operator<<=(const safe_int& x) {
    val_t r = val>>(NBITS-x.val);
    if (r!=0 && r!=-1) {
      throw overflow();
    }
    val <<= x.val;
    return *this;
  }

  // These are implemented in terms of other operators, which do checking:
  safe_int& operator++()                      { return (*this) += 1; }
  safe_int& operator--()                      { return (*this) -= 1; }

  // (Does Boost.Operators provide unary operator- ?)
  // safe_int operator-() { ... }


  // It would probably be reasonable to allow a different type for the RHS of most of these 
  // operators.  Boost.Integer has some code to do this, but I have not investigated it.

};

};


#endif

