// TcpClientSocket.hh
// This file is part of libpbe; see http://decimail.org/
// (C) 2006-2007 Philip Endecott

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

#ifndef libpbe_TcpClientSocket_hh
#define libpbe_TcpClientSocket_hh

#include <string>

#include "FileDescriptor.hh"
#include "ip.hh"


namespace pbe {

class TcpClientSocket: public FileDescriptor {

private:
  const std::string host;
  const short port;

public:
  TcpClientSocket(std::string host_, short port_):
    FileDescriptor(tcp_client_connect(host_,port_)),
    host(host_), port(port_)
  {}
};

};

#endif
