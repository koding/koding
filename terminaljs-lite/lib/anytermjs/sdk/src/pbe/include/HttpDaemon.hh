// HttpDaemon.hh
// This file is part of libpbe; see http://anyterm.org/
// (C) 2005-2007 Philip Endecott

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

#ifndef HttpDaemon_hh
#define HttpDaemon_hh

#include "Daemon.hh"
#include "HttpRequest.hh"
#include "HttpResponse.hh"
#include "HttpAuthenticator.hh"
#include "FileDescriptor.hh"

#include <string>


namespace pbe {


class HttpDaemon: public Daemon {

private:
  HttpAuthenticator* const authenticator;
  const bool keepalive;

public:
  HttpDaemon(short port=80, std::string progname="httpd", std::string user="",
             bool keepalive_=true, int max_connections=0, bool accept_local_only=false):
    Daemon(port, progname, LOG_LOCAL0, user, "", max_connections, accept_local_only),
    authenticator(NULL),
    keepalive(keepalive_) {}

  HttpDaemon(HttpAuthenticator& a, short port=80, std::string progname="httpd",
	     std::string user="", bool keepalive_=true, int max_connections=0,
             bool accept_local_only=false):
    Daemon(port, progname, LOG_LOCAL0, user, "", max_connections, accept_local_only),
    authenticator(&a), keepalive(keepalive_) {}

  void session(pbe::FileDescriptor& in_fd, pbe::FileDescriptor& out_fd);

  virtual void session_start() {}
  virtual void handle(const HttpRequest& req, HttpResponse& resp) = 0;

  void authenticate(HttpRequest& req);
};


};


#endif
