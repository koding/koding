// include/FileMonitor.cc
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

#ifndef pbe_FileMonitor_hh
#define pbe_FileMonitor_hh

#include "FileDescriptor.hh"
#include "Exception.hh"
#include "missing_syscalls.hh"

#include <linux/inotify.h>


namespace pbe {

#if defined(PBE_HAVE_INOTIFY_INIT) && defined(PBE_HAVE_INOTIFY_ADD_WATCH)

static inline int check_inotify_init() {
  int rc = ::inotify_init();
  if (rc==-1) {
    pbe::throw_ErrnoException("inotify_init()");
  }
  return rc;
}

class FileMonitor {

  int fdnum;
  pbe::FileDescriptor fd;

public:
  FileMonitor(std::string fn):
    fdnum(check_inotify_init()),
    fd(fdnum,"inotify handle")
  {
    int rc = ::inotify_add_watch(fdnum,fn.c_str(),IN_MODIFY);
    if (rc==-1) {
      pbe::throw_ErrnoException("inotify_add_watch()");
    }
  }

  void wait_until_modified() {
    struct inotify_event ev;
    fd.binread(ev);
  }

  bool wait_until_modified_or_timeout(float timeout) {
    bool readable = fd.wait_until_readable_or_timeout(timeout);
    if (!readable) {
      return false;
    }
    struct inotify_event ev;
    fd.binread(ev);
    return true;
  }


};

#endif

};


#endif

