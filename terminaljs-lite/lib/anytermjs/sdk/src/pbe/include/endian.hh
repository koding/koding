// src/endian.hh
// This file is part of libpbe; see http://decimail.org
// (C) 2006 Philip Endecott

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

#ifndef libpbe_endian_hh
#define libpbe_endian_hh

#include <arpa/inet.h>

#ifdef __GLIBC__
#include <endian.h>
#define PBE_BYTE_ORDER __BYTE_ORDER
#define PBE_BIG_ENDIAN __BIG_ENDIAN
#define PBE_LITTLE_ENDIAN __LITTLE_ENDIAN

#elif defined(__FreeBSD__)
#include <machine/endian.h>
#define PBE_BYTE_ORDER _BYTE_ORDER
#define PBE_BIG_ENDIAN _BIG_ENDIAN
#define PBE_LITTLE_ENDIAN _LITTLE_ENDIAN

#endif


namespace pbe {

inline uint32_t swap_end_32(uint32_t data)
{
  uint32_t r = data>>24;
  r |= (data>>8)&0x0000ff00;
  r |= (data<<8)&0x00ff0000;
  r |= data<<24;
  return r;
}

inline uint64_t swap_end_64(uint64_t data)
{
  uint64_t a = swap_end_32(data>>32);
  uint64_t b = swap_end_32(data&0xffffffff);
  return a | b<<32;
}


inline uint64_t hton64(uint64_t i) {
#if PBE_BYTE_ORDER == PBE_BIG_ENDIAN
  return i;
#else
  return swap_end_64(i);
#endif
}


inline uint64_t ntoh64(uint64_t i) {
#if PBE_BYTE_ORDER == PBE_BIG_ENDIAN
  return i;
#else
  return swap_end_64(i);
#endif
}


};

#endif
