// include/URI.hh
// This file is part of libpbe; see http://svn.chezphil.org/libpbe/
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

#ifndef libpbe_URI_hh
#define libpbe_URI_hh

#include <string>

#include <boost/cstdint.hpp>
#include <boost/lexical_cast.hpp>

// URIs per RFC2396.
// All URIs have a scheme - well, except for relative URIs outside their
// context - but the form of the rest is scheme-dependent.  However,
// schemes that are hierarchical have a common syntax for hierarchy, and
// schemes that involve the network have a common syntax for indicating
// the remote host.  This URI class is intended primarily for these schemes
// i.e. HTTP, HTTPS, and FTP.


namespace pbe {


class URI {

public:
  URI(): port(0) {}
  URI(std::string absolute_uri);
  URI(std::string scheme_, std::string host_, std::string abs_path_,
      std::string query_="", uint16_t port_=0, std::string userinfo_=""):
    scheme(scheme_), userinfo(userinfo_), host(host_), port(port_),
    abs_path(abs_path_), query(query_)
  {}

  // The names of the following fields match the rules in the RFC2396 EBNF.
  std::string scheme;
  std::string userinfo;
  std::string host;
  uint16_t port;  // port is set to zero if it's not specified; this class doesn't
                  // know about protocol-specific default port numbers.
  std::string abs_path;
  std::string query;
  // Example:  http://joe@example.com:8080/path/to/foo.cgi?a=1
  // scheme=http, userinfo=joe, host=example.com, port=8080,
  // abs_path=/path/to/foo.cgi, quary=a=1

  struct SyntaxError {};

  std::string str() const {
    std::string s = scheme + "://";
    if (!userinfo.empty()) {
      s += userinfo + "@";
    }
    s += host;
    if (port!=0) {
      s += ":" + boost::lexical_cast<std::string>(port);
    }
    s += abs_path;
    if (!query.empty()) {
      s += "?" + query;
    }
    return s;
  }

};


};


#endif

