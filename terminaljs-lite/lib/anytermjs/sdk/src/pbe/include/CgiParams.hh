// include/CgiParams.hh
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
#ifndef libpbe_CgiParams_hh
#define libpbe_CgiParams_hh

#include <string>
#include <map>
using namespace std;


// CGI parameters

// Provides a mechanism to access form parameters passed from the
// browser.

// The CgiParams class makes the parameters available as a key-value
// map (it inherits from map<string,string>.

// CGI parameters can be passed from the browser, via the server, in
// three formats.

// For forms with METHOD="GET" (indicated in the CGI program by the
// REQUEST_METHOD environment variable having the value GET), the
// parameters are passed over HTTP as part of the URI, and arrive at
// the CGI program in the QUERY_STRING environment variable.
// E.g. http://www.foo.com/cgi-bin/blobby.cgi?name=phil&blah=33 Note
// that & or ; can be used to separate paramters; if & is used, it
// must be escaped in HTML.  Keys and values are separated by =.  Keys
// and values are URI-encoded ( + is space, %nn hex for other odd
// characters).

// For forms with METHOD="POST", the parameters are passed over HTTP
// in the "body" of the request, and arrive at the CGI program on
// stdin.  They can be encoded in one of two ways, indicated by the
// CONTENT_TYPE environment variable.

// If the content-type is "application/x-www-form-urlencoded", the data
// is in the same format as for the GET method: name=phil&blah=33.

// If the content-type is multipart/form-data, the data is encoded in
// a MIME style.


// The load() method for class CgiParams will determine which
// mechanism is in use, and do whatever decoding is necessary.


class CgiParams: public map<string,string> {
public:
  CgiParams(void) {}
  void load(void);

  string get(string name) const;
  string get_default(string name, string def) const;

private:
  void init_from_urlencoded(string query_string);
  void init_from_multipart(string input, string boundary);
};


#endif
