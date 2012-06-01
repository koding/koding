// include/HttpRequest.hh
// This file is part of libpbe; see http://anyterm.org/
// (C) 2006-2008 Philip Endecott

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


#ifndef libpbe_HttpRequest_hh
#define libpbe_HttpRequest_hh

#include "URI.hh"

#include <string>
#include <map>


namespace pbe {


struct HttpRequest {
  std::string method;
  std::string host;
  std::string abs_path;
  std::string query;
  std::string http_version;
  std::string userinfo;
  typedef std::map<std::string,std::string> headers_t;
  headers_t headers;
  std::string body;

  HttpRequest() {}

  HttpRequest(const URI& uri, std::string method_="GET", std::string http_version_="HTTP/1.1"):
    method(method_),
    host(uri.host),
    abs_path(uri.abs_path),
    query(uri.query),
    http_version(http_version_),
    userinfo(uri.userinfo)
  {
    headers["Host"]=host;
  }

  std::string request_line() const {
    return method
          +" "
          +abs_path + (query.empty() ? std::string() : "?"+query)
          +" "
          +http_version+"\r\n";
  }

  std::string headers_str() const {
    std::string s;
    for (headers_t::const_iterator i = headers.begin();
         i != headers.end(); ++i) {
      s += i->first + ": " + i->second + "\r\n";
    }
    return s;
  }
    
};


};


#endif
