// include/fixed.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
// It is also offered as a candidate for inclusion in Boost, http://boost.org/
// (C) 2007 Philip Endecott
// This file is distributed under the terms of the Boost Software License v. 1.0,
// see http://www.boost.org/LICENSE_1_0.txt.

// Introduction
// ------------

// This file provides class templates 'fixed' and 'ufixed' which implement signed and 
// unsigned fixed-point arithmetic.  For background information about fixed-point 
// arithmetic, see for example this Wikipedia article: 
// http://en.wikipedia.org/wiki/Fixed-point_arithmetic.  Note in particular that this 
// is binary arithmetic, not binary coded decimal.
// 
// The author's requirement for fixed-point arithmetic is based on these 
// characteristics:
// 
// - Comparing a 32-bit fixed-point value and a 32-bit single-precision 
// floating-point value, the fixed-point value has about 8 bits more precision 
// because it does not "waste" bits representing the exponent.  In the case of 
// latitude and longitude values this makes the difference between a precision of 
// hundreds of metres and ones of metres.
// 
// - Certain operations that directly operate on the bit patterns of values are much 
// simpler to carry out on fixed-point values than on floating-point values.  (For 
// example, the bit interleaving required for Z-curves.)
// 
// Other characteristics that are often beneficial include:
// 
// - Computation is faster on systems that have no floating-point hardware, e.g. 
// embedded systems.
// 
// - The precision of the values is well-defined and predictable.
// 
// 
// Quick Start
// -----------
// 
// Here's a very quick illustration of how the class can be used:
// 
// #include <fixed.hpp>
// 
// void test() {
//   fixed<15,16> f1, f2;  // Signed fixed-point values with 15 bits of integer part 
//                         // and 16 bits of fractional part.
//   f1 = 1.2345;   // Conversion from floating point.
//   f2 = f1 - 2;   // Mixed arithmetic with integers.
//   f2 = f1 / f2;  // Arithmetic on fixed-point values.
// }
// 
// 
// Primary Objective
// -----------------
// 
// The primary objective of this implementation is zero performance overhead compared 
// to using integer arithmetic with manually-inserted scaling.  This is because 
// performance is important in many applications of fixed-point arithmetic and it 
// really isn't very hard to do ad-hoc fixed-point arithmetic using integers and 
// shifts.  Users will therefore not be attracted to this library unless it can offer 
// this feature.
//  
// 
// Secondary Objectives
// --------------------
// 
// Secondary objectives are:
// 
// - To behave in as many respects as possible in the same was as the built-in 
// numeric types (integer and floating-point).  The motivation for this is to give 
// the user the behaviour that they are already familiar with from those types.
// 
// 
// Hardware Support
// ----------------
// 
// The objective of this implementation is to work efficiently with conventional 
// processors' integer arithmetic instructions.  It is worth noting, however, that 
// some processors have hardware support for fixed-point operations.  These include:
// 
// [Hmm, no MMX doesn't seem to have any explicit fixed-point support]
// 
// - DSP processors.
// - Intel's MMX instruction set (also implemented in other x86-compatible 
// processors).
// - The PowerPC's AltiVec instruction set.
// - The ARM Piccolo instruction set.
// 
// Support for any of these instruction sets would require either use of
// architecture-specific assembly language or a very smart compiler.  These are 
// considered outside the scope of the current work; however, it is worthwhile to see 
// what these instruction sets offer in order to avoid unintentionally implementing 
// something that is incompatible.
// 
// For example, it seems that these instruction sets could more easily support 
// fixed<16,15> than fixed<15,16>.  It may be that the user would be happy with 
// either of these formats.  So we should consider offering a way to get the "best" 
// format with at least a certain number of bits of integer and fractional parts for 
// a particular instruction set.
// 
// 
// Related Work
// ------------
// 
// "Embedded C" (see ISO/IEC [draft] technical report 18037:2004) proposes fixed 
// point types for C.  It defines 
// new keywords _Fract and _Accum which modify the built-in short, int and long 
// types; _Fract makes the value entirely fractional while _Accum gives it 4 
// integer bits.
// 
// It requires saturating arithmetic (controlled by an _Sat keyword or a #pragma), 
// and does not require wrap-around behaviour.  
// 
// Fixed-point constants can be written using letter suffixes, e.g. 3.1415uhk.
// 
// It looks very much as if this proposal is motivated by one particular category of 
// applications (i.e. digital signal processing).  The requirement for saturating 
// arithmetic imposes a significant overhead on processors that do not have support 
// for it, and the lack of support for values with more than 4 integer bits makes it 
// useless for the author's latitude/longitude application.
// 
// 
// Getting the High part of a multiply result
// ------------------------------------------
// 
// MMX has "packed multiply high" instruction.
// 
// 
// Meaning of ++ and --
// --------------------
// 
// It could be argued that the meaning of ++ and -- is unclear: do they add/subtract 
// 1, or do they add/subtract the type's delta?  (...there is an example of something 
// where they do delta...).  I note, however, that the built-in floating point types 
// add and subtract 1, as does the proposed "Embedded C" fixed-point type.  
// Therefore, ++ and -- are defined to do that for fixed and ufixed.
// 
// 
// Fixed Point Constants
// ---------------------
// 
// It would be ideal if code such as
// 
//   const ufixed<2,14> pi = 3.1415926;
// 
// could have no run-time overhead.  To be investigated...
// 
// 
// Result Types
// ------------
// 
// 
// Free Functions
// --------------
// 
// embedded C has...
// ...names are crytic due to absence of template/overloading in C.
// 
// 
// Overflow and Saturation
// -----------------------
// 
// Users of fixed-point arithmetic sometimes want to detect overflow, or for 
// operations to saturate when overflow would occur.  However, users of 
// floating-point and integer arithmetic also sometimes want these features, but they 
// are not provided by the built-in C/C++ types.  The approach taken in this 
// implementation is to follow the behaviour of the built-in types, i.e. to not 
// handle overflow; values will wrap-around.  
// 
// Hardware overhead of saturation; MMX has saturating instructions.
// 
// 
// Division By Zero
// ----------------
// 
// compare with int and float...
// 
// embedded C fixed is undefined
// 
// 
// Formatted input/output
// ----------------------
// 
// ... implemented by conversion to floating point? ...
// 
// 
// 'Math library' functions
// ------------------------
// 
// A set of functions similar to those provided by the standard library for integer 
// and floating-point types is provided.  The skeleton for these functions was 
// provided by ......
// 
// In the case of ....., tables of constants are required.  Different tables are 
// required for each fixed point type.  By default, the approach taken is to compute 
// these tables when the functions are first used [note that the use of static 
// variables may not be thread safe].  This could impose an unacceptable delay in 
// some applications; in this case, the preprocessor symbol ... should be defined, 
// and the included program ... should be run once for each type to generate static 
// tables.  Simply include the output of this program in your build.
// 
// 
// bigint
// ------
// 
// 
// Benchmarks
// ----------
// 
// The following results are based on the benchmark programs in the ... directory.  
// There are:
// 
// - sort: generates a std::vector of xxxx pseudo-random values and sorts them 
// using std::sort.  This measures comparison performance, which should be of the 
// same order as addition and subtraction.
// 
// - filt: generates a vector of pseudo-random values and filters them using an FIR 
// (finite impulse response) filter.  The filter coefficients are also generated 
// pseudo-randomly.  This measures primarily multiply performance.
// 
// In each case the performance is measured for fixed-point, floating-point and 
// integer types with manually-inserted shifts.
// 
// The following platforms have been tested:
// 
// - NSLU2.  (See http://nslu2-linux.org/).  This system has a 266 MHz Intel IXP420 
// XScale ARM processor, which has no floating point hardware.  The compiler used was 
// g++ verson 4.1.2.
// 
// - The author's desktop computer, which as a 1 GHz VIA C3 (x86-compatible) 
// processor.  The compiler used was also g++ version 4.1.2.
// 



// Note to Boost people: I will change all the 'libpbe' identifiers to 'boost' 
// when this is formally proposed for review.

#ifndef libpbe_fixed_hh
#define libpbe_fixed_hh

#include <cmath>  // for ldexp*
#include "./integer.hpp"  // Copy of boost::integer to which I've added 64-bit support.
                          // I expect this functionality to be added to the official
                          // version before this code is reviewed.
#include <boost/integer/static_min_max.hpp>
#include <boost/operators.hpp>


namespace pbe {


// This helper function exists mainly to avoid warnings about negative shifts.

template <int amt, typename T>
T shift(T val) {
  if (amt>0) {
    unsigned int u_amt = amt;
    return val>>u_amt;
  } else { 
    unsigned int u_amt = -amt;
    return val<<u_amt;
  }
}



template <int WB, int FB, typename VAL_T = typename boost::int_t<WB+FB+1>::least>
// WB = Whole Bits
// FB = Fraction Bits
// VAL_T = type to use for implementation
class fixed:

  boost::totally_ordered<fixed<WB,FB,VAL_T> >,
  boost::additive<fixed<WB,FB,VAL_T> >,
  boost::bitwise<fixed<WB,FB,VAL_T> >,
  boost::unit_steppable<fixed<WB,FB,VAL_T> >
{

// Question: do we want to expose the implementation type and value?
// In my application I have found it useful to do so.
//private:
public:
  typedef VAL_T val_t;
  val_t val;

public:
  fixed() {}
  fixed(const fixed& x): val(x.val) {}

  template <int X_WB, int X_FB, typename X_VAL_T>
  fixed(const fixed<X_WB, X_FB, X_VAL_T>& x):
    val(shift<X_FB-FB>(x.val))
        //(X_FB<FB)
        //?(x.val<<(FB-X_FB))
        //:(x.val>>(X_FB-FB)))
    {}

  fixed(int x):    val(x<<FB) {}
  fixed(float x):  val(static_cast<val_t>(ldexpf(x,FB))) {}
  fixed(double x): val(static_cast<val_t>(ldexp (x,FB))) {}

  operator float()  const { return ldexpf(static_cast<double>(val),-FB); }
  operator double() const { return ldexp (static_cast<double>(val),-FB); }


  bool operator<(const fixed& x) const  { return val<x.val; }
  bool operator==(const fixed& x) const { return val==x.val; }
  fixed& operator+=(const fixed& x)     { val+=x.val; return *this; }
  fixed& operator-=(const fixed& x)     { val-=x.val; return *this; }
  fixed& operator|=(const fixed& x)     { val|=x.val; return *this; }
  fixed& operator&=(const fixed& x)     { val&=x.val; return *this; }
  fixed& operator^=(const fixed& x)     { val^=x.val; return *this; }
  fixed& operator++()                   { return (*this) += 1; }  // Hmm, maybe not wanted
  fixed& operator--()                   { return (*this) -= 1; }  // ditto.

  fixed operator-() { fixed f = *this; f.val = -f.val; return f; }

  template <int XWB, int XFB, typename X_VAL_T>
  fixed& operator*=(const fixed<XWB,XFB,X_VAL_T>& x) { (*this) = (*this) * x; return *this; }

  template <int XWB, int XFB, typename X_VAL_T>
  fixed& operator/=(const fixed<XWB,XFB,X_VAL_T>& x) { (*this) = (*this) / x; return *this; }

  fixed& operator*=(float x) { (*this) = static_cast<float>(*this) * x; return *this; }

  fixed& operator/=(float x) { (*this) = static_cast<float>(*this) / x; return *this; }
};


// I don't know how to choose the VAL_T for the results of these operations.
// I.e. if the operands use safe_int then the result should also use safe_int.

template <int XWB, int XFB, typename X_VAL_T, int YWB, int YFB, typename Y_VAL_T>
pbe::fixed<boost::static_unsigned_max<XWB,YWB>::value, boost::static_unsigned_max<XFB,YFB>::value> 
operator+(pbe::fixed<XWB,XFB,X_VAL_T> x, pbe::fixed<YWB,YFB,Y_VAL_T> y) {
  typedef pbe::fixed<boost::static_unsigned_max<XWB,YWB>::value, boost::static_unsigned_max<XFB,YFB>::value> result_t;
  result_t x_(x);
  result_t y_(y);
  return x_ + y_;
}


template <int XWB, int XFB, typename X_VAL_T, int YWB, int YFB, typename Y_VAL_T>
pbe::fixed<boost::static_unsigned_max<XWB,YWB>::value, boost::static_unsigned_max<XFB,YFB>::value> 
operator-(pbe::fixed<XWB,XFB,X_VAL_T> x, pbe::fixed<YWB,YFB,Y_VAL_T> y) {
  typedef pbe::fixed<boost::static_unsigned_max<XWB,YWB>::value, boost::static_unsigned_max<XFB,YFB>::value> result_t;
  result_t x_(x);
  result_t y_(y);
  return x_ - y_;
}


template <int XWB, int XFB, typename X_VAL_T, int YWB, int YFB, typename Y_VAL_T>
pbe::fixed<XWB+YWB,XFB+YFB>
operator*(pbe::fixed<XWB,XFB,X_VAL_T> x, pbe::fixed<YWB,YFB,Y_VAL_T> y) {
  typedef pbe::fixed<XWB+YWB,XFB+YFB> result_t;
  result_t r;
  r.val = static_cast<typename result_t::val_t>(x.val) * y.val;
  return r;
}


template <int XWB, int XFB, typename X_VAL_T, int YWB, int YFB, typename Y_VAL_T>
pbe::fixed<XWB+YFB,XFB+YWB>
operator/(pbe::fixed<XWB,XFB,X_VAL_T> x, pbe::fixed<YWB,YFB,Y_VAL_T> y) {
  pbe::fixed<XWB+YFB,XFB+YWB> r;
  r.val = x.val;
  r.val <<= (YWB+YFB);
  r.val /= y.val;
  return r;
}


template <int XWB, int XFB, typename X_VAL_T>
float operator*(pbe::fixed<XWB,XFB,X_VAL_T> x, float y) {
  // fixed * float is done using floating-point.  Right choice?
  return static_cast<float>(x) * y;
}

template <int XWB, int XFB, typename X_VAL_T>
float operator/(pbe::fixed<XWB,XFB,X_VAL_T> x, float y) {
  // Ditto.
  return static_cast<float>(x) / y;
}



// Also planned: an unsigned version.


};


#endif

