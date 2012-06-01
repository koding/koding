// src/segv_backtrace.cc
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/trunk
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

#include "segv_backtrace.hh"

// This is available on glibc on Linux; I'm not sure about other platforms.
#ifdef __linux__

#include <execinfo.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "compiler_magic.hh"

#define max_backtrace_size 200

static void print_backtrace(int signum)
{
  signal(SIGSEGV,SIG_DFL);
  signal(SIGBUS,SIG_DFL);
  signal(SIGILL,SIG_DFL);
  signal(SIGFPE,SIG_DFL);
  const char* signame;
  switch(signum) {
    case SIGSEGV: signame="Segmentation fault";  break;
    case SIGBUS:  signame="Bus error";           break;
    case SIGILL:  signame="Illegal instruction"; break;
    case SIGFPE:  signame="FP exception";        break;
    default:      signame="unexpected signal";   break;
  }
  ::write(2,signame,::strlen(signame));
  const char* msg=" detected; Backtrace:\n";
  ::write(2,msg,::strlen(msg));
  void* return_addrs[max_backtrace_size];
  size_t n_return_addrs = ::backtrace(return_addrs,max_backtrace_size);
  ::backtrace_symbols_fd(return_addrs,n_return_addrs,2);
  raise(signum);
}


void get_backtrace_on_segv()
{
  struct sigaction s;
  s.sa_handler = &print_backtrace;
  sigfillset(&s.sa_mask);
  s.sa_flags=0;
  sigaction(SIGSEGV,&s,NULL);
  sigaction(SIGBUS,&s,NULL);
  sigaction(SIGILL,&s,NULL);
  sigaction(SIGFPE,&s,NULL);
}

#else
// Platform doesn't have these functions, so no-op.

void get_backtrace_on_segv()
{
}

#endif

