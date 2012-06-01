// src/Daemon.cc
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

#include "Daemon.hh"

#include "Exception.hh"
#include "Lock.hh"
#include "Thread.hh"

#include <boost/bind.hpp>

#include <unistd.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include <pwd.h>
#include <sys/resource.h>
#include <sstream>
#include <fstream>

using namespace std;
using namespace pbe;


static void handle_foreground_exception(Exception& E)
{
  E.report(cerr);
  exit(E.exit_status);
}


static void handle_background_exception(Exception& E)
{
  ostringstream s;
  E.report(s);
  syslog(LOG_ERR,"Unhandled exception: %s",s.str().c_str());
}


Daemon::Daemon(short p, string n, int sf, string u, string d, int max_sessions_,
               bool accept_local_only_):
  port(p), progname(n), syslog_facility(sf), username(u), dir(d),
  max_sessions(max_sessions_ ? max_sessions_ : default_max_sessions), 
  accept_local_only(accept_local_only_),
  n_sessions(0)
{}


Daemon::~Daemon()
{}


void Daemon::run_interactively(void)
{
  FileDescriptor fdin(0);
  FileDescriptor fdout(1);
  try {
    try {
      startup();
      session(fdin,fdout);
    }
    RETHROW_MISC_EXCEPTIONS;
  }
  catch(Exception& E) {
    handle_foreground_exception(E);
  }
}


void Daemon::decrement_session_count()
{
  {
    Lock<n_sessions_mutex_t> l(n_sessions_mutex);
    --n_sessions;
  }
  n_sessions_condition.notify_all();
}

static void run_session(Daemon* daemon, int connfd_n)
{
  try {
    try {
      //syslog(LOG_INFO,"new session starting");
      FileDescriptor connfd(connfd_n);
      daemon->session(connfd,connfd);
      //syslog(LOG_INFO,"session finished");
      daemon->decrement_session_count();
      return;
    }
    RETHROW_MISC_EXCEPTIONS;
  }
  catch(Exception& E) {
    handle_background_exception(E);
    // what do we want to do after an exception in a session?
    // presumably continue?  alternative is to quit the entire process.
    // exit(E.exit_status);
    daemon->decrement_session_count();
  }
}


void handle_signal(int signo)
{
  syslog(LOG_CRIT,"got signal %s",strsignal(signo));

  switch(signo) {

  case SIGHUP:
    // Hangup - often means "restart" for daemons, but we ignore it.
    signal (SIGHUP, handle_signal);
    return;

  case SIGPIPE:
    // Wrote to a closed pipe.
    // This signal is now ignored, so this case is never reached.
    // We must detect closed sockets by checking the return values
    // of system calls.
    // The difficulty with SIGPIPE is that it is unclear which thread
    // receives it - it may not be the one doing the write(), according
    // to some web references - and even then, I don't know how the
    // signal handler could then cause an exception (or whatever) in
    // the corresponding session code.  Horrible.
    return;

  default:
    // Other signals e.g. INT, SEGV etc.
    // Terminate entire process.
    // Could consider terminating a single thread.
    syslog(LOG_CRIT,"terminating");
    exit(1);
  }

  // remember signal need to be re-enabled if the handler is going to
  // return
}


void Daemon::run_as_daemon(bool background)
{
  signal (SIGHUP,  handle_signal);
  signal (SIGINT,  handle_signal);
  //signal (SIGQUIT, SIG_DFL);  // This means we can kill -QUIT and dump core
  signal (SIGILL,  handle_signal);
  signal (SIGBUS,  handle_signal);
  signal (SIGFPE,  handle_signal);
  signal (SIGSEGV, handle_signal);
  signal (SIGTERM, handle_signal);
  signal (SIGPIPE, SIG_IGN);
  signal (SIGABRT, handle_signal);
 
  openlog(progname.c_str(),LOG_PID,syslog_facility);

  try {
    try {

      // set umask?
      
      int listenfd = socket(PF_INET,SOCK_STREAM,0);
      // Add SO_KEEPALIVE so we get SIGPIPE if connection fails?
      if(listenfd==-1) {
	throw_ErrnoException("socket()");
      }
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
      server_addr.sin_addr.s_addr=htonl( accept_local_only ? INADDR_LOOPBACK : INADDR_ANY );
      server_addr.sin_port=htons(port);
      int r = bind(listenfd,(struct sockaddr*)&server_addr,sizeof(server_addr));
      if (r==-1) {
	throw_ErrnoException("bind()");
      }

      // The parameter to listen is the "backlog" parameter, the number un-accepted
      // connections allowed before the connection is refused.
      r = listen(listenfd,8);
      if (r==-1) {
	throw_ErrnoException("listen()");
      }

      if (background) {
        // cd to /
        // disconnect std[in|out|err];
        // fork; parent process exits.
        r = daemon(0,0);
        if(r) {
          throw_ErrnoException("daemon()");
        }
      }

      // Errors now go to syslog
      try {
	try {

	  // Create PID file
	  // Need to do this after daemon() else we get the wrong pid
	  if (getuid()==0) {
	    string pidfilename = "/var/run/"+progname+".pid";
	    ofstream pidfile(pidfilename.c_str());
	    pidfile << getpid() << endl;
	    pidfile.close();
	  }
	  // Can't delete this file at termination as we don't have
	  // the neccessary permissions then - does this matter?
      
	  syslog(LOG_INFO,"%s starting",progname.c_str());

	  // Start as root in order to bind to a reserved port
	  // Having bound, give up root and run as the specified daemon user
	  if (getuid()==0 && username!="") {
	    struct passwd* pw = getpwnam(username.c_str());
	    if (!pw) {
	      throw_ErrnoException("getpwnam(\""+username+"\")");
	    }
	    int rc = setuid(pw->pw_uid);
	    if (rc==-1) {
	      throw_ErrnoException("seteuid()");
	    }
	  }

	  // Change working directory, if requested.
	  // This was added so that core files can go somewhere sensible.
          if (dir!="") {
	    int rc = chdir(dir.c_str());
	    if (rc==-1) {
	      throw_ErrnoException("chdir("+dir+")");
	    }
          }
	  
          // If we dump core, it may be a large core file if we have many threads
          // running, and some systems set an rlimit that breaks this.  If this is
          // a soft rlimit we can increase it here.  If for some reason we can't
          // increase it we won't treat it as an error.  Note that we're doing this
          // having changed user to the run-as user.
	  struct rlimit unlimited_cores;
	  unlimited_cores.rlim_cur = RLIM_INFINITY;
	  unlimited_cores.rlim_max = RLIM_INFINITY;
	  setrlimit(RLIMIT_CORE,&unlimited_cores);

	  startup();
      
	  while(1) {
	
            {
              Lock<n_sessions_mutex_t> l(n_sessions_mutex);
              while (n_sessions >= max_sessions) {
                n_sessions_condition.wait(l);
              }
            }

	    struct sockaddr_in client_addr;
	    socklen_t client_size=sizeof(client_addr);
	    int connfd_n;
            do {
              connfd_n = accept(listenfd,(struct sockaddr*)&client_addr,
                                &client_size);
            } while (connfd_n==-1 && errno==EINTR);
	    if (connfd_n==-1) {
	      throw_ErrnoException("accept()");
	    }
            // race condition here
            int rc = fcntl(connfd_n,F_SETFD,FD_CLOEXEC);
            if (rc==-1) {
              throw_ErrnoException("fcntl(connfd_n,F_SETFD,FD_CLOEXEC)");
            }
	    
            {
              Lock<n_sessions_mutex_t> l(n_sessions_mutex);
              ++n_sessions;
            }
	    
	    Thread t(boost::bind(&run_session,this,connfd_n));
	  }
	}
	RETHROW_MISC_EXCEPTIONS;
      }
      catch(Exception& E) {
        if (background) {
          handle_background_exception(E);
        } else {
          handle_foreground_exception(E);
        }
	exit(E.exit_status);
      }
      
    }
    RETHROW_MISC_EXCEPTIONS;
  }
  catch(Exception& E) {
    handle_foreground_exception(E);
  }
}


void Daemon::run_default(void)
{
  if (isatty(0)) {
    run_interactively();
  } else {
    run_as_daemon();
  }
}

