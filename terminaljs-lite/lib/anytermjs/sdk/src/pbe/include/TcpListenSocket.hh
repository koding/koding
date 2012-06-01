// TcpListenSocket.hh
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

#ifndef libpbe_TcpListenSocket_hh
#define libpbe_TcpListenSocket_hh

#include <string>

#include "FileDescriptor.hh"

#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>


namespace pbe {

class TcpListenSocket: public FileDescriptor {

  static int create_tcp_listen_socket(short port) {
    int listenfd = socket(PF_INET,SOCK_STREAM,0);
    if (listenfd==-1) {
      throw_ErrnoException("socket()");
    }
    try {
      // race condition here
      int rc = fcntl(listenfd,F_SETFD,FD_CLOEXEC);
      if (rc==-1) {
        throw_ErrnoException("fcntl(listenfd,F_SETFD,FD_CLOEXEC)");
      }

      // Not sure what this does
      const int t=1;
      setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &t, sizeof(t));

      struct sockaddr_in server_addr;
      memset(&server_addr,0,sizeof(server_addr));
      server_addr.sin_family=AF_INET;
      server_addr.sin_addr.s_addr=htonl(INADDR_ANY);
      server_addr.sin_port=htons(port);
      int r = bind(listenfd,reinterpret_cast<struct sockaddr*>(&server_addr),sizeof(server_addr));
      if (r==-1) {
        throw_ErrnoException("bind()");
      }

      // 128 is the "backlog" parameter.
      r = listen(listenfd,128);
      if (r==-1) {
        throw_ErrnoException("listen()");
      }
    } catch(...) {
      ::close(listenfd);
      throw;
    }
    return listenfd;
  }

public:
  TcpListenSocket(short port):
    FileDescriptor(create_tcp_listen_socket(port))
  {}

  int accept() {
    struct sockaddr_in client_addr;
    socklen_t client_size=sizeof(client_addr);
    int connfd = ::accept(fd,reinterpret_cast<struct sockaddr*>(&client_addr),&client_size);
    if (connfd==-1) {
      throw_ErrnoException("accept()");
    }
    try {
      // race condition here
      int rc = fcntl(connfd,F_SETFD,FD_CLOEXEC);
      if (rc==-1) {
        throw_ErrnoException("fcntl(connfd,F_SETFD,FD_CLOEXEC)");
      }
    } catch(...) {
      ::close(connfd);
      throw;
    }
    return connfd;
  }
};

};

#endif
