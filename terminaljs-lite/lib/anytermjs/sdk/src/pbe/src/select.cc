// src/select.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004-2005 Philip Endecott

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

#include "select.hh"

#include "Exception.hh"

#include <sys/select.h>

#include <cmath>
#include <algorithm>

using namespace std;
using namespace pbe;


int select_r(int fd1)
{
  fd_set rd_fds;
  FD_ZERO(&rd_fds);
  fd_set wr_fds;
  FD_ZERO(&wr_fds);
  fd_set ex_fds;
  FD_ZERO(&ex_fds);

  FD_SET(fd1,&rd_fds);

  int rc;
  do {
    rc = select(fd1+1,&rd_fds,&wr_fds,&ex_fds,NULL);
    if (rc==-1) {
      if (errno==EINTR) {
        continue;
      }
      throw_ErrnoException("select()");
    }
    break;
  } while (1);

  if (FD_ISSET(fd1,&rd_fds)) {
    return fd1;
  }

  return -2;
}


int select_rr(int fd1, int fd2)
{
  fd_set rd_fds;
  FD_ZERO(&rd_fds);
  fd_set wr_fds;
  FD_ZERO(&wr_fds);
  fd_set ex_fds;
  FD_ZERO(&ex_fds);

  FD_SET(fd1,&rd_fds);
  FD_SET(fd2,&rd_fds);

  int rc;
  do {
    rc = select(max(fd1,fd2)+1,&rd_fds,&wr_fds,&ex_fds,NULL);
    if (rc==-1) {
      if (errno==EINTR) {
        continue;
      }
      throw_ErrnoException("select()");
    }
  } while (0);

  if (FD_ISSET(fd1,&rd_fds)) {
    return fd1;
  } else if (FD_ISSET(fd2,&rd_fds)) {
    return fd2;
  }

  return -2;
}


int select_rt(int fd1, float timeout)
{
  fd_set rd_fds;
  FD_ZERO(&rd_fds);
  fd_set wr_fds;
  FD_ZERO(&wr_fds);
  fd_set ex_fds;
  FD_ZERO(&ex_fds);

  FD_SET(fd1,&rd_fds);

  struct timeval tv;
  float timeout_whole;
  float timeout_frac;
  timeout_frac = modff(timeout, &timeout_whole);
  tv.tv_sec = (int)timeout_whole;
  tv.tv_usec = (int)(1000000.0*timeout_frac);

  int rc;
  do {
    rc = select(fd1+1,&rd_fds,&wr_fds,&ex_fds,&tv);
    if (rc==-1) {
      if (errno==EINTR) {
        continue;
      }
      throw_ErrnoException("select()");
    }
  } while (0);

  if (rc==0) {
    return -1;
  } else if (FD_ISSET(fd1,&rd_fds)) {
    return fd1;
  }

  return -2;
}
