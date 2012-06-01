// include/bloom_filter.hh
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


#ifndef bloom_filter_hh
#define bloom_filter_hh

#include <tr1/array>

// This class implements an approximation to set<KEY_TYPE> using a Bloom Filter.
// It's approximate in the senses that:
// - It sometimes returns false positives.  (It never returns false negatives.)
// - It provides only a subset of the features of a real set, in particular it does
//   not support iteration or erasure of elements.  Only insertion and testing are
//   provided.
//
// Insertion and testing are both O(1) in the number of keys stored.
//
// See e.g. the Wikipedia Bloom Filter page for the theory.
// 
// There are a few template parameters that you need to set:
// Choose n_bits based on the acceptable probability of false positives (f) and the
// number of stored keys (n_keys) to satisfy:
//      f = 0.618 ^ (n_bits/n_keys)
// =>   n_bits = n_keys ln(f)/-0.48
// It's best to round n_bits to a power of 2; if you don't, mod is needed
// at run-time.  In any case it must be a multiple of 32.
// Space is O(n_bits).
//
// Choose n_hashes using
//      n_hashes = 0.7 n_bits / n_keys
// Insertion and testing are O(n_hashes).  Using fewer hashes will make these operations
// faster at the expense of more false positives; this can be offset by increasing
// n_bits i.e. trading off time vs. space.  Using more hashes will NOT reduce the rate of
// false positivies.
//
// (Hmm, I now wonder if the better approach is to choose n_hashes based on f, and then
// to choose n_bits.)
//
// So for example, to store the 56840 words in /usr/share/dict/words with a probability
// of a false positive of 1% (i.e. 1% of your mis-spellings are identified as correct),
// we get n_bits = 545329 which rounds down to 512*1024 or up to 1024*1024.  n_hashes
// is 9 or 18 respectively.
//
// These values are theoretical optimums; in practice you may need to experiment a bit
// to find good values if you're fussy about the space required and the false positive rate.
//
// You need to supply a hash function.  It takes the key as an argument and returns a tr1::array
// of n_hashes hash values, which much each have at least log2(n_bits) bits.
// Possible sources of hash functions are:
// - The standard library includes them, returning size_t, for integer types and std::string.
// - Boost.CRC.
//
// In cases where you want to do the same insert or lookup on multiple filters, it makes
// sense to do the hash calculation only once.  To allow this the insert and check methods
// are overloaded with versions that take hash results.


template < typename KEY_TYPE,
           int n_bits,
           int n_hashes,
           typename HASH
         >
class bloom_filter {
public:
  typedef KEY_TYPE key_type;
  typedef std::tr1::array< unsigned int, n_hashes > hash_return_type;

  bloom_filter() {
    bits_t b_ = {{0}};
    bits = b_;
  }

  void insert(const hash_return_type& h) {
    for (int k=0; k<n_hashes; ++k) {
      set_bit(h[k]%n_bits);
    }
  }

  void insert(const key_type& key) {
    hash_return_type h = HASH()(key);
    insert(h);
  }

  bool check(const hash_return_type& h) const {
    for (int k=0; k<n_hashes; ++k) {
      if (!test_bit(h[k]%n_bits)) {
        return false;
      }
    }
    return true;
  }

  bool check(const key_type& key) const {
    hash_return_type h = HASH()(key);
    return check(h);
  }

private:
  typedef std::tr1::array< uint32_t, (n_bits+31) &~ 31 > bits_t;
  bits_t bits;

  void set_bit(int n) {
    bits[n>>5] |= 1<<(n&31);
  }

  bool test_bit(int n) const {
    return bits[n>>5] & (1<<(n&31));
  }
};


#endif

