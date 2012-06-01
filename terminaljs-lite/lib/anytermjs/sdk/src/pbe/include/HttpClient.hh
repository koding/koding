#ifndef libpbe_HttpClient_hh
#define libpbe_HttpClient_hh

// include/HttpClient.hh
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


#include "URI.hh"
#include "HttpResponse.hh"

#include <string>


namespace pbe {


class HttpClient {

  std::string user_agent;

  template <typename Processor, bool use_etag>
  void get_process_save(const URI& uri, std::string fn, int redirect_hops);

public:
  HttpClient(std::string user_agent_="libpbe::HttpClient"):
    user_agent(user_agent_)
  {}

  HttpResponse get(const URI& uri, int redirect_hops=10);

  void get_save(const URI& uri, std::string fn, int redirect_hops=10);
  void get_save_with_etag(const URI& uri, std::string fn, int redirect_hops=10);

  void get_gunzip_save(const URI& uri, std::string fn, int redirect_hops=10);
  void get_gunzip_save_with_etag(const URI& uri, std::string fn, int redirect_hops=10);

#ifdef HAVE_BZIP
  void get_bunzip_save(const URI& uri, std::string fn, int redirect_hops=10);
  void get_bunzip_save_with_etag(const URI& uri, std::string fn, int redirect_hops=10);
#endif
};


};


#endif

