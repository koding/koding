// include/Daemon.hh
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

#ifndef libpbe_Daemon_hh
#define libpbe_Daemon_hh

#include <syslog.h>
#include <string>

#include "FileDescriptor.hh"
#include "Mutex.hh"
#include "Condition.hh"

// TODO:
// Sending EOF doesn't do anything (sigpipe?)
// Worry about other signals
// Spurious thread on first connection (is it syslog???)


class Daemon {
public:
  static const int default_max_sessions = 25;

  Daemon(short p,
	 std::string pn,
	 int sf = LOG_LOCAL0,
	 std::string u="",
	 std::string d="",
         int max_sessions_=0,
         bool accept_local_only_=false);
  virtual ~Daemon();

  void run_interactively(void);
  void run_as_daemon(bool background = true);
  void run_default(void);

  virtual void startup(void) {};
  virtual void session(pbe::FileDescriptor& in_fd, pbe::FileDescriptor& out_fd) = 0;

private:
  const short port;
  const std::string progname;
  const int syslog_facility;
  const std::string username;
  const std::string dir;
  const int max_sessions;
  const bool accept_local_only;

  typedef pbe::Mutex<> n_sessions_mutex_t;
  n_sessions_mutex_t n_sessions_mutex;
  typedef pbe::Condition n_sessions_condition_t;
  n_sessions_condition_t n_sessions_condition;
  int n_sessions;

public: // really private
  void decrement_session_count(void);
};


#endif
