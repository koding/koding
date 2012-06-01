// src/run_cmd.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2005, 2007 Philip Endecott

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

#include "run_cmd.hh"

#include "Exception.hh"

#include <stdio.h>
#include <sys/wait.h>

using namespace std;
using namespace pbe;

namespace pbe {

string run_cmd( string cmd, bool& exit_ok )
{
  cmd+=" 2>&1";
  FILE* p = popen(cmd.c_str(),"r");
  if (!p) {
    throw_ErrnoException("popen("+cmd+")");
  }

  string result;
  while (1) {
    const int bfsz=1024;
    char buf[bfsz];
    int n = fread(buf,sizeof(char),bfsz,p);
    result.append(buf,n);
    if (n<bfsz) {
      break;
    }
  }

  int rc = pclose(p);
  if (rc==-1) {
    throw_ErrnoException("pclose()");
  }

  exit_ok = WIFEXITED(rc) && (WEXITSTATUS(rc)==0);

  return result;
}


string run_cmd( string cmd )
{
  bool exit_ok;
  string r = run_cmd(cmd,exit_ok);
  if (!exit_ok) {
    throw_ErrnoException("run_cmd("+cmd+")");
  }
  return r;
}

};

