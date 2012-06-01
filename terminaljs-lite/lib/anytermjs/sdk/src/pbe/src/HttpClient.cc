// src/HttpClient.hh
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

#include "HttpClient.hh"

#include "HttpRequest.hh"
#include "TcpClientSocket.hh"
#include "Gunzipper.hh"
#include "Bunzipper.hh"
#include "FileDescriptor.hh"
#include "rfcdate.hh"
#include "FileType.hh"
#include "atomic_ofstream.hh"

#include <iostream>
#include <algorithm>

using namespace std;


namespace pbe {


HttpResponse HttpClient::get(const URI& uri, int redirect_hops)
{
  if (uri.scheme != "http") {
    throw "Not an HTTP URI";
  }
  HttpRequest req(uri);
  req.headers["Date"] = rfc_date();
  req.headers["Connection"] = "close";
  req.headers["User-Agent"] = user_agent;
  TcpClientSocket sock(uri.host, uri.port ? uri.port : 80);
  sock.writeall(req.request_line() + req.headers_str() + "\r\n");
  HttpResponse response(sock.readall());
  if (response.status_code==301 || response.status_code==302
   || response.status_code==303 || response.status_code==307) {
    if (redirect_hops<=0) {
      throw "Redirection limit reached";
    }
    return get(response.headers["Location"], redirect_hops-1);
  }
  return response;
}


template <typename Processor, bool use_etag>
void HttpClient::get_process_save(const URI& uri, std::string fn, int redirect_hops)
{
  if (uri.scheme != "http") {
    throw "Not an HTTP URI";
  }
  const string etag_fn = fn+".etag";
  HttpRequest req(uri);
  req.headers["Date"] = rfc_date();
  req.headers["Connection"] = "close";
  req.headers["User-Agent"] = user_agent;
  if (use_etag && file_exists(etag_fn) && file_exists(fn)) {
    ifstream etagf(etag_fn.c_str());
    string etag;
    getline(etagf,etag);
    req.headers["If-None-Match"] = etag;
  }
  TcpClientSocket sock(uri.host, uri.port ? uri.port : 80);
  sock.writeall(req.request_line() + req.headers_str() + "\r\n");

  string resp_start;
  string::iterator crlf2pos;
  do {
    bool timed_out = wait_until(sock.readable(), 30)==-1;
    if (timed_out) {
      throw TimedOut("read()");
    }
    resp_start.append(sock.readsome());
    string crlf2 = "\r\n\r\n";
    crlf2pos = search(resp_start.begin(),resp_start.end(), crlf2.begin(),crlf2.end());
  } while (crlf2pos==resp_start.end());
  HttpResponse response(string(resp_start.begin(),crlf2pos+4));

  if (use_etag && response.status_code==304) {
    return;
  }

  if (response.status_code==301 || response.status_code==302
   || response.status_code==303 || response.status_code==307) {
    if (redirect_hops<=0) {
      throw "Redirection limit reached";
    }
    get_process_save<Processor,use_etag>(response.headers["Location"], fn, redirect_hops-1);
    return;
  }

  if (response.status_code != 200) {
    throw response;
  }

  string tmp_fn = fn+".part";

  {
    FileDescriptor fd(tmp_fn,FileDescriptor::create);
    try {
      Processor proc;
      fd.writeall(proc(string(crlf2pos+4,resp_start.end())));

      while (1) {
        bool timed_out = wait_until(sock.readable(), 30)==-1;
        if (timed_out) {
          throw TimedOut("read()");
        }
        string s = sock.readsome();
        if (s.empty()) {
          break;
        }
        fd.writeall(proc(s));
      }
    }
    catch (...) {
      unlink(tmp_fn.c_str());
      throw;
    }
  }

  // Ideally we should rename both the data file and the etag file atomically, but
  // we can't do that.  A safe alternative is to delete the old etag file first; in this
  // case the worst that can happen is that we end up with a valid data file and a
  // missing etag file.

  if (use_etag) {
    unlink(etag_fn.c_str());
  }

  int rc = rename(tmp_fn.c_str(),fn.c_str());
  if (rc==-1) {
    throw_ErrnoException("rename("+tmp_fn+","+fn+")");
  }

  if (use_etag && response.headers.find("ETag")!=response.headers.end()) {
    atomic_ofstream etagf(etag_fn);
    etagf << response.headers["ETag"];
    etagf.commit();
  }
}


struct identity_processor {
  std::string operator()(string s) const { return s; }
};


void HttpClient::get_save(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<identity_processor,false>(uri,fn,redirect_hops);
}

void HttpClient::get_save_with_etag(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<identity_processor,true>(uri,fn,redirect_hops);
}


void HttpClient::get_gunzip_save(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<Gunzipper,false>(uri,fn,redirect_hops);
}

void HttpClient::get_gunzip_save_with_etag(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<Gunzipper,true>(uri,fn,redirect_hops);
}


#ifdef HAVE_BZIP

void HttpClient::get_bunzip_save(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<Bunzipper,false>(uri,fn,redirect_hops);
}  

void HttpClient::get_bunzip_save_with_etag(const URI& uri, std::string fn, int redirect_hops)
{
  return get_process_save<Bunzipper,true>(uri,fn,redirect_hops);
}  


#endif

};
