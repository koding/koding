// src/SmtpClient.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004 Philip Endecott

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
#include "SmtpClient.hh"

#include "ip.hh"
#include "select.hh"

#include <syslog.h>
#include <unistd.h>

#include<cstdio>

#ifdef __OpenBSD__
// Is this really needed?
#include <sys/types.h>
#endif

using namespace std;
using namespace pbe;


  void SmtpError::report(ostream& s) const
  {
    s << msg;
  }


  SmtpClient::SmtpClient(bool log): enable_log(log), connected(false)
  {}


  void SmtpClient::connect(string server_name, string domain, int port)
  {
    fd = tcp_client_connect(server_name, port);

    wait_for_reply(220,300);
    send("EHLO "+domain);
    wait_for_reply(250,300);

    connected=true;
  }
  
  
  void SmtpClient::wait_for_reply(int expected_code, int timeout)
  {
    if (select_rt(fd,timeout)==-1) {
      throw SmtpError("Timeout");
    }
    char buf[513];
    int n=0;
    while (1) {
      int c = read(fd,buf+n,sizeof(buf)-n);
      buf[n+c+1]='\0';
      if (enable_log) {
	syslog(LOG_MAIL|LOG_DEBUG,"SmtpClient:S: %s",buf);
      }
      if (c==-1) {
	throw_ErrnoException("read()");
      }
      n += c;
      if (buf[n-1]=='\n') {
	break;
      }
      if (n==sizeof(buf)) {
	throw SmtpError("Command line did not terminate");
      }
    }
    int code;
    int rc = sscanf(buf,"%d",&code);
    if (rc!=1) {
      throw SmtpError("No reply code at start of line");
    }
    if (code != expected_code) {
      throw SmtpError("Unexpected reply: \'"+string(buf)+"\'");
    }
  }


  void SmtpClient::send(string d)
  {
    if (enable_log) {
      syslog(LOG_MAIL|LOG_DEBUG,"SmtpClient:C: %s",d.c_str());
    }
    d.append("\r\n");
    // ought to impose a timeout on these writes
    const char* p = d.data();
    int n = d.length();
    int c = 0;
    while(c<n) {
      int rc = write(fd,p+c,n-c);
      if (rc==-1) {
	throw_ErrnoException("write()");
      }
      c += rc;
    }
  }

  
  void SmtpClient::send_msg(string sender, string recipient, string msg)
  {
    list<string> recipients;
    recipients.push_back(recipient);
    send_msg(sender, recipients, msg);
  }


  void SmtpClient::send_msg(string sender, const list<string>& recipients,
			    string msg)
  {
    send("MAIL FROM:<"+sender+">");
    wait_for_reply(250,300);
    for (list<string>::const_iterator i = recipients.begin();
	 i != recipients.end(); ++i) {
      send("RCPT TO:<"+*i+">");
      wait_for_reply(250,300); // could get 251 as well
    }
    send("DATA");
    wait_for_reply(354,120);
    send(msg);
    send(".");
    wait_for_reply(250,600);
  }


  void SmtpClient::disconnect(void)
  {
    send("QUIT");
    wait_for_reply(221,300);
    int rc = close(fd);
    if (rc==-1) {
      throw_ErrnoException("close()");
    }
    connected=false;
  }
