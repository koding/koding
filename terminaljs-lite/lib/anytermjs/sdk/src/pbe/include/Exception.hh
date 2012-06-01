// src/Exception.hh
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

#ifndef libpbe_Exception_hh
#define libpbe_Exception_hh

#include <errno.h>

#include <iostream>
#include <string>


namespace pbe {

class Exception
{
public:
  Exception(void): exit_status(1) {}
  virtual ~Exception() {}
  virtual void report(std::ostream& s) const = 0;
  const int exit_status;
};


class StrException: public Exception
{
private:
  const std::string msg;
public:
  StrException(std::string s): msg(s) {}
  void report(std::ostream& s) const { s << msg << std::endl; }
};


class StdException: public Exception
{
private:
  std::string msg;
public:
  StdException(std::exception& e): msg(e.what()) {}
  void report(std::ostream& s) const { s << msg << std::endl; }
};


class UnknownException: public Exception
{
public:
  void report(std::ostream& s) const;
};


class ErrnoException: public Exception
{
private:
  int error_number;
  std::string doing_what;

public:
  ErrnoException(std::string dw, int errno_=errno): error_number(errno_), doing_what(dw) {}
  int get_errno(void) { return error_number; }
  void report(std::ostream& s) const;
};


struct NoSuchFileOrDirectory: public ErrnoException {
  NoSuchFileOrDirectory(std::string dw):
    ErrnoException(dw) {}
};

struct ConnectionRefused: public ErrnoException {
  ConnectionRefused(std::string dw):
    ErrnoException(dw) {}
};

struct NoSuchDevice: public ErrnoException {
  NoSuchDevice(std::string dw):
    ErrnoException(dw) {}
};

struct HostUnreachable: public ErrnoException {
  HostUnreachable(std::string dw):
    ErrnoException(dw) {}
};

struct NoDataAvailable: public ErrnoException {
  NoDataAvailable(std::string dw):
    ErrnoException(dw) {}
};

struct BrokenPipe: public ErrnoException {
  BrokenPipe(std::string dw):
    ErrnoException(dw) {}
};

struct Overflow: public ErrnoException {
  Overflow(std::string dw):
    ErrnoException(dw) {}
};

struct InvalidArgument: public ErrnoException {
  InvalidArgument(std::string dw):
    ErrnoException(dw) {}
};

struct WouldBlock: public ErrnoException {
  WouldBlock(std::string dw):
    ErrnoException(dw) {}
};

struct TimedOut: public ErrnoException {
  TimedOut(std::string dw):
    ErrnoException(dw) {}
};

struct IOError: public ErrnoException {
  IOError(std::string dw):
    ErrnoException(dw) {}
};

struct InterruptedSysCall: public ErrnoException {
  InterruptedSysCall(std::string dw):
    ErrnoException(dw) {}
};

struct NoSpace: public ErrnoException {
  NoSpace(std::string dw):
    ErrnoException(dw) {}
};

inline void throw_ErrnoException(std::string dw, int errno_=errno) {
  switch (errno_) {
    case ENOENT:       throw NoSuchFileOrDirectory(dw);
    case ECONNREFUSED: throw ConnectionRefused(dw);
    case ENODEV:       throw NoSuchDevice(dw);
    case EHOSTUNREACH: throw HostUnreachable(dw);
#ifdef ENODATA
// FreeBSD doesn't have ENODATA
    case ENODATA:      throw NoDataAvailable(dw);
#endif
    case EPIPE:        throw BrokenPipe(dw);
    case EOVERFLOW:    throw Overflow(dw);
    case EINVAL:       throw InvalidArgument(dw);
    case EWOULDBLOCK:  throw WouldBlock(dw);
    case ETIMEDOUT:    throw TimedOut(dw);
    case EIO:          throw IOError(dw);
    case EINTR:        throw InterruptedSysCall(dw);
    case ENOSPC:       throw NoSpace(dw);
    default:           throw ErrnoException(dw,errno_);
  }
}


#define RETHROW_MISC_EXCEPTIONS \
catch(pbe::Exception& E) {      \
  throw;                        \
}                               \
catch(std::exception& e) {      \
  throw pbe::StdException(e);   \
}                               \
catch(const char* s) {          \
  throw pbe::StrException(s);   \
}                               \
catch(std::string s) {          \
  throw pbe::StrException(s);   \
}                               \
catch(...) {                    \
  throw pbe::UnknownException();\
}


};


#endif
