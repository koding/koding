// src/ip.hh
// This file is part of libpbe; see http://decimail.org
// (C) 2004-2007 Philip Endecott

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

#ifndef libpbe_ip_hh
#define libpbe_ip_hh

#include "Exception.hh"

#include <netdb.h>
#include <netinet/in.h>

#include <iostream>
#include <string>


namespace pbe {


std::ostream& operator<<(std::ostream& s, struct in_addr ip);


class HostLookupError: public Exception
{
private:
  std::string hostname;
  int error_code;
public:
  HostLookupError(std::string h, int e): hostname(h), error_code(e) {}
  void report(std::ostream& s) const;
};


struct in_addr get_ip_address(std::string hostname);

std::string get_own_hostname(void);

int tcp_client_connect(std::string server_name, int port);

int local_client_connect(std::string address);


};


#endif
