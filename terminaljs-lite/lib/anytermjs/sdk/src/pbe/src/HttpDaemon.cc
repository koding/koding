// HttpDaemon.cc
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


#include "HttpDaemon.hh"

#include "HttpRequest.hh"
#include "parse_http_request.hh"
#include "HttpResponse.hh"
#include "rfcdate.hh"

#include <iostream>
#include <sstream>

using namespace std;


namespace pbe {


void HttpDaemon::session(FileDescriptor& in_fd, FileDescriptor& out_fd)
{
  session_start();

#ifndef LIBPBE_HAS_FILEDESCRIPTOR_STREAMS
#error "Sorry, there is a problem with your compiler / C++ library.  Please ask for assistance"
#endif
  FileDescriptor::istream in_strm(in_fd);

  bool close_connection=!keepalive;
  do {
    HttpRequest req;
    HttpResponse resp;
    try {
      try {
	req = parse_http_request(in_strm);
	// Should look at Host: header and consider complete URIs in
	// request line
	if (req.http_version!="HTTP/1.1") {
	  // We should send a 1.0 response if the request was for 1.0; i.e.
          // we should send a content-length header and not use chunked encoding.
	  close_connection=true;
	}
	if (req.headers["Connection"]=="close") {  
	  // could be other tokens in the line.  Should be case-insensitive.
	  close_connection=true;
	}
	if (req.headers.find("Host")==req.headers.end()) {
	  resp.status_code=400;
	  resp.reason_phrase="Bad Request (missing Host: header)";
	  
	} else if (req.method!="GET" && req.method!="POST") {
	  resp.status_code=405;
	  resp.reason_phrase="Method not allowed";
	  resp.headers["Allow"]="GET POST";
	  // should check for Expect: header and reject with 417 response.
	  
	} else {
	  handle(req,resp);
	}
      }
      catch (HttpRequestSyntaxError& E) {
	resp.status_code=400;
	resp.reason_phrase="Malformed request";
	close_connection=true;
      }
      catch (HttpAuthenticator::NotAuthenticated& NA) {
	resp.status_code=401;
	resp.reason_phrase="Unauthorised";
	resp.headers["WWW-Authenticate"]="Basic realm=\"Anyterm\"";
      }
      RETHROW_MISC_EXCEPTIONS;
    }
    catch (Exception& E) {
      resp.status_code=500;
      ostringstream s;
      s << "Server error: ";
      E.report(s);
      resp.reason_phrase=s.str();
    }
    if (resp.status_code!=200) {
      close_connection=true;
      // Actually we don't need to do this, but maybe it is safer
    }
    if (close_connection) {
      resp.headers["Connection"]="close";
    }
    resp.headers["Date"]=rfc_date();
    resp.send(out_fd);
  } while (!close_connection);
}



void HttpDaemon::authenticate(HttpRequest& req)
{
  if (authenticator) {
    HttpRequest::headers_t::const_iterator i = req.headers.find("Authorization");
    if (i==req.headers.end()) {
      throw HttpAuthenticator::NotAuthenticated();
    }
    string credentials = i->second;
    req.userinfo = (*authenticator)(credentials);
  }
}


};

