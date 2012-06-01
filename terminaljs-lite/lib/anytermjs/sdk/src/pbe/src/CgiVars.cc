// src/CgiVars.hh
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


#include "CgiVars.hh"

#include <stdlib.h>

using namespace std;


void CgiVars::setvar(const char* varname)
{
  const char* envvar = getenv(varname);
  if (envvar) {
    (*this)[varname]=envvar;
  } else {
    (*this)[varname]="";
  }
}


void CgiVars::load(void)
{
  setvar("SERVER_SOFTWARE");
  setvar("SERVER_NAME");
  setvar("GATEWAY_INTERFACE");
  setvar("SERVER_PROTOCOL");
  setvar("SERVER_PORT");
  setvar("REQUEST_METHOD");
  setvar("PATH_INFO");
  setvar("PATH_TRANSLATED");
  setvar("SCRIPT_NAME");
  setvar("QUERY_STRING");
  setvar("REMOTE_HOST");
  setvar("AUTH_TYPE");
  setvar("REMOTE_USER");
  setvar("REMOTE_IDENT");
  setvar("CONTENT_TYPE");
  setvar("CONTENT_LENGTH");

  setvar("HTTP_USER_AGENT");
  setvar("HTTP_COOKIE");
  setvar("HTTP_IF_MODIFIED_SINCE");
  setvar("HTTP_IF_NONE_MATCH");

  setvar("HTTPS");
}


/*static*/ const CgiVars& CgiVars::singleton(void)
{
  static CgiVars cgivars;
  static bool loaded=false;

  if (!loaded) {
    cgivars.load();
    loaded=true;
  }
  return cgivars;
}
