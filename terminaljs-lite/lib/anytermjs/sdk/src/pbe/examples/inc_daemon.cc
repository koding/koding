// examples/inc_daemon.cc
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
// Demo program for Daemon class

// The Daemon class does the mucky stuff needed to implement a
// "daemon" (i.e. a server, e.g. imapd, httpd etc) process.

// You make a subclass of Daemon that:
// * Provides "void session(int in_fd, int out_fd)" that does the work.
//   File descriptors for input and output to the connection are supplied.
// * Calls the Daemon base class constructor with port number, program
//   name (used in syslog calls) and optional syslog "facility" code (see
//   man syslog).
//
// Your main program then creates an instance of your Daemon subclass and
// invokes one of three run_*() methods, as shown below.

// This example implements a trivial "inc" daemon that reads a number
// from the user, increments it, and returns the incremented value.


// libpbe includes:

#include "Daemon.hh"
#include "Exception.hh"

// Standard includes:

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;


// To demonstrate exception handling, if the user enters 666 this
// exception is thrown.
class NumberOfTheBeast: public Exception {
public:
  void report(ostream& s) {
    s << "The number of the beast!" << endl;
  }
};


class IncDaemon: public Daemon {

public:
  IncDaemon(void): Daemon(1705,"inc_daemon") {}

  
  // Here is the session function that is called to handle a new
  // connection.  It is run in its own thread.
  void session(int in_fd, int out_fd)
  {
    // I don't know how to make a C++ stream from a file descriptor.
    FILE* inf = fdopen(in_fd,"r");
    FILE* outf = fdopen(out_fd,"w");

    fprintf(outf,"Please enter numbers to increment.\n");
    int r=1;
    // check for EOF is important - it indicates connection is closed
    while(!feof(inf) && !ferror(inf) && !ferror(outf)) {
      fprintf(outf,"> ");
      fflush(outf);
      int n;
      r = fscanf(inf,"%d",&n);
      if (r==0 || r==EOF) {
	break;
      }
      if (n==666) {
	throw NumberOfTheBeast();
      }
      fprintf(outf,"--->%d<---\n",n+1);
    }
    if (r==0) {
      fprintf(outf,"fscanf() didn't get a number\n");
    }
    if (r==EOF) {
      fprintf(outf,"fscanf() returned EOF\n");
    }
    if (feof(inf)) {
      fprintf(outf,"EOF on input\n");
    }
    if (ferror(inf)) {
      fprintf(outf,"Error on input(!)\n");
    }
    if (ferror(outf)) {
      fprintf(outf,"Error on output(!)\n");
    }
    fflush(outf);
  }
};



int main(int argc, char* argv[])
{
  IncDaemon d;
  if (argc==1) {
    // Guess whether to run in interactive or daemon mode based on isatty(0)
    d.run_default();
  } else if (argc==2) {
    string a(argv[1]);
    if (a=="-i") {
      // Run interactively, i.e. not a daemon at all
      d.run_interactively();
    } else if (a=="-d") {
      // Run as a daemon
      cout << "Daemon about to start.  Telnet to port 1705." << endl;
      d.run_as_daemon();
    } else {
      cerr << "Unrecognised option '" << a << "'" << endl;
      exit(1);
    }
  } else {
    cerr << "Too many options" << endl;
    exit(1);
  }
}
