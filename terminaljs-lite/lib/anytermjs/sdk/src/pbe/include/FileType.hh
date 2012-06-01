// src/FileType.hh
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


// Determine the type of a pathname: regular file, directory, symlink, etc.


#ifndef libpbe_FileType_hh
#define libpbe_FileType_hh

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <string>

#include "Exception.hh"


namespace pbe {

  enum FileType { file, directory, symlink, does_not_exist, other };

  static inline FileType filetype_from_stat(struct stat& stat_buf)
  {
    if (S_ISDIR(stat_buf.st_mode)) {
      return directory;
    } else if (S_ISREG(stat_buf.st_mode)) {
      return file;
    } else if (S_ISLNK(stat_buf.st_mode)) {
      return symlink;
    } else {
      return other;
    }
  }

  inline FileType get_filetype(std::string pathname, bool report_noexist=false)
  {
    struct stat stat_buf;
    int ret = stat(pathname.c_str(),&stat_buf);
    if (ret==-1) {
      if (report_noexist && errno==ENOENT) {
        return does_not_exist;
      }
      throw_ErrnoException("stat("+pathname+")");
    }
    return filetype_from_stat(stat_buf);
  }

  inline FileType get_link_filetype(std::string pathname, bool report_noexist=false)
  {
    struct stat stat_buf;
    int ret = lstat(pathname.c_str(),&stat_buf);
    if (ret==-1) {
      if (report_noexist && errno==ENOENT) {
        return does_not_exist;
      }
      throw_ErrnoException("lstat("+pathname+")");
    }
    return filetype_from_stat(stat_buf);
  }

  inline FileType get_fd_filetype(int fd)
  {
    struct stat stat_buf;
    int ret = fstat(fd,&stat_buf);
    if (ret==-1) {
      throw_ErrnoException("fstat()");
    }
    return filetype_from_stat(stat_buf);
  }

  inline bool file_exists(std::string pathname)
  {
    struct stat stat_buf;
    int ret = stat(pathname.c_str(),&stat_buf);
    if (ret==-1) {
      if (errno==ENOENT) {
        return false;
      }
      throw_ErrnoException("stat("+pathname+")");
    }
    return true;
  }

};

#endif

