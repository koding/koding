// src/Directory.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004 Philip Endecott

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

#include "Directory.hh"

#include "Exception.hh"

#include <unistd.h>

using namespace std;

namespace pbe {


Directory::Directory(string dirname_):
  dirname(dirname_)
{}


Directory::~Directory()
{}


void Directory::const_iterator::operator++(void)
{
  read_next();
}


bool Directory::const_iterator::operator==(const const_iterator& rhs) const
{
  if (!at_end && !rhs.at_end) {
    throw "Cannot compare these Directory::const_iterators";
  }
  return at_end==rhs.at_end;
}


Directory::const_iterator::const_iterator(void):
  dir(NULL), at_end(true)
{}


Directory::const_iterator::const_iterator(string dirname_):
  dirname(dirname_), at_end(false)
{
  dir = opendir(dirname.c_str());
  if (!dir) {
    throw_ErrnoException("opendir("+dirname+")");
  }
  read_next();
}


Directory::const_iterator::~const_iterator()
{
  if (dir) {
    int ret = closedir(dir);
    if (ret==-1) {
      // throw_ErrnoException("closing a directory");
      // Don't throw an exception from a destructor, in case it is being invoked 
      // during exception processing.
      // (TODO is there a better fix for this?)
    }
  }
}


void Directory::const_iterator::read_next(void)
{
  struct dirent* ent_p = readdir(dir);
  if (!ent_p) {
    at_end=true;
  } else {
    this_entry.leafname = ent_p->d_name;
    if (this_entry.leafname=="." || this_entry.leafname=="..") {
      read_next();
      return;
    }
    this_entry.pathname = dirname + '/' + this_entry.leafname;
  }
}


Directory::const_iterator Directory::begin(void) const
{
  return const_iterator(dirname);
}


Directory::const_iterator Directory::end(void) const
{
  return const_iterator();
}

};

