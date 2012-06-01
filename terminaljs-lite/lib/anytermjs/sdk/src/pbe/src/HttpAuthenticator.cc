// HttpAuthenticator.cc
// This file is part of libpbe; see http://anyterm.org/
// (C) 2005 Philip Endecott

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


#include "HttpAuthenticator.hh"

#include "base64.hh"

using namespace std;
using namespace pbe;


string HttpAuthenticator::operator()(string credentials) const
{
  if (credentials.substr(0,6)!="Basic ") {
    // should be case-insensitive
    throw NotAuthenticated();
  }
  string user_pass_b64 = credentials.substr(6);

  string user_pass = decode_base64(user_pass_b64);
  unsigned int colon_pos = user_pass.find(':');
  string username = user_pass.substr(0,colon_pos);
  string password = user_pass.substr(colon_pos+1);

  basic_auth(username,password);

  return username;
}
