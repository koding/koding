// src/SmtpClient.hh
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
#ifndef libpbe_SmtpClient_hh
#define libpbe_SmtpClient_hh

#include "Exception.hh"

#include <string>
#include <list>
using namespace std;


  class SmtpError: public pbe::Exception {
  private:
    string msg;
  public:
    SmtpError(string m): msg(m) {}
    void report(ostream& s) const;
  };


  class SmtpClient {
  public:
    SmtpClient(bool log=false);
    void connect(string server_name, string domain, int port=25);
    bool is_connected(void) { return connected; }
    void send_msg(string sender, string recipient, string msg);
    void send_msg(string sender, const list<string>& recipients, string msg);
    void disconnect(void);

  private:
    const bool enable_log;
    bool connected;
    int fd;

    void wait_for_reply(int expected_code, int timeout);
    void send(string d);
  };

#endif
