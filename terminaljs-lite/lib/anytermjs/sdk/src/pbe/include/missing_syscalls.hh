// include/missing_syscalls.hh
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

#ifndef pbe_missing_syscalls_hh
#define pbe_missing_syscalls_hh

#include <sys/syscall.h>
#include <unistd.h>
#include <sys/time.h>
#include <stdint.h>


#ifdef __NR_futex
inline int futex(int  *uaddr,  int  op, int val, const struct timespec *timeout, int *uaddr2, int val3) 
{
  return syscall(__NR_futex,uaddr,op,val,timeout,uaddr2,val3);
}
#endif

#ifdef __NR_gettid
inline int gettid()
{
  return syscall(__NR_gettid);
}
#endif

#ifdef __NR_tkill
inline int tkill(int tid, int sig)
{
  return syscall(__NR_tkill,tid,sig);
}
#endif

#ifdef __NR_delete_module
inline int delete_module(const char* name)
{
  return syscall(__NR_delete_module,name);
}
#endif


// These are missing from my glibc, but they may be present in newer versions:

#ifdef __NR_inotify_init
#define PBE_HAVE_INOTIFY_INIT 1
inline int inotify_init(void)
{
  return syscall(__NR_inotify_init);
}
#endif

#ifdef __NR_inotify_add_watch
#define PBE_HAVE_INOTIFY_ADD_WATCH
inline int inotify_add_watch(int fd, const char* pathname, uint32_t mask)
{
  return syscall(__NR_inotify_add_watch,fd,pathname,mask);
}
#endif



#endif

