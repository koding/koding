// src/ip.cc
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

#include "ip.hh"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netdb.h>
#include <unistd.h>

using namespace std;


namespace pbe {


ostream& operator<<(ostream& s, struct in_addr ip)
{
  uint32_t i = ntohl(ip.s_addr);
  s << ((i&0xff000000)>>24)
    << '.' << ((i&0x00ff0000)>>16)
    << '.' << ((i&0x0000ff00)>>8)
    << '.' << (i&0x000000ff);
  return s;
}


void HostLookupError::report(ostream& s) const {
  s << "host name lookup failed for " << hostname << ": "
    << gai_strerror(error_code) << endl;
}


struct in_addr get_ip_address(string hostname)
{
  struct addrinfo ai;
  memset(&ai, 0, sizeof(ai));
  ai.ai_family = AF_INET;
  
  struct addrinfo* res;
  int rc = getaddrinfo(hostname.c_str(), "", &ai, &res);
  if (rc) {
    throw HostLookupError(hostname,rc);
  }

  struct in_addr result = ((sockaddr_in *)(res->ai_addr))->sin_addr;
  freeaddrinfo(res);

  return result;
}


string get_own_hostname(void)
{
  char name[256];
  int rc = gethostname(name,sizeof(name));
  if (rc!=0) {
    throw_ErrnoException("gethostname()");
  }
  
  struct addrinfo ai;
  memset(&ai, 0, sizeof(ai));
  ai. ai_flags = AI_CANONNAME;
  ai.ai_family = AF_INET;
  
  struct addrinfo* res;
  // FIXME Is there any way to specify a timeout?
  rc = getaddrinfo(name, "", &ai, &res);
  if (rc) {
    throw HostLookupError(name,rc);
  }

  string result(res->ai_canonname);
  freeaddrinfo(res);

  return result;
}

    
  
int tcp_client_connect(string server_name, int port)
{
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_addr = get_ip_address(server_name);
  addr.sin_port = htons(port);

  int fd = socket(PF_INET,SOCK_STREAM,0);
  if (fd==-1) {
    throw_ErrnoException("socket()");
  }
  // FIXME if we wanted to detect a timeout here we should make fd nonblocking;
  // this will cause connect() to return with errno==EINPROGRESS; we then select()
  // until fd is writeable (or times out), at which point we call getsockopt(SO_ERROR)
  // to get any connect error.
  int rc = connect(fd, (struct sockaddr*)&addr, sizeof(addr));
  if (rc==-1) {
    throw_ErrnoException("connect()");
  }

  return fd;
}


int local_client_connect(string address)
{
  struct sockaddr_un addr;
  addr.sun_family = AF_LOCAL;
  strcpy(addr.sun_path,address.c_str());

  int fd = socket(PF_LOCAL,SOCK_STREAM,0);
  if (fd==-1) {
    throw_ErrnoException("socket()");
  }
  int rc = connect(fd, (struct sockaddr*)&addr, SUN_LEN(&addr));
  if (rc==-1) {
    throw_ErrnoException("connect()");
  }

  return fd;
}


};

