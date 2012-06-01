// SerialPort.hh
// This file is part of libpbe; see http://anyterm.org/
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


#ifndef libpbe_SerialPort_hh
#define libpbe_SerialPort_hh

#include "FileDescriptor.hh"
#include "Exception.hh"

#include <string>
#include <boost/lexical_cast.hpp>

#include <termios.h>
#include <unistd.h>


namespace pbe {

class SerialPort: public FileDescriptor {

public:
  SerialPort(std::string fn, open_mode_t open_mode, int baudrate, bool raw=true):
    FileDescriptor(fn,open_mode)
  {
    set_serial_mode(baudrate,raw);
  }

  SerialPort(std::string fn, open_mode_t open_mode):
    FileDescriptor(fn,open_mode)
  {}

  SerialPort(int fd):
    FileDescriptor(fd)
  {}

  void set_serial_mode(int baudrate, bool raw=true) {
    struct termios settings;
    int rc = tcgetattr(fd, &settings);
    if (rc<0) {
      throw_ErrnoException("tcgetattr("+fn+")");
    }
    if (raw) {
      cfmakeraw(&settings);
    }
    rc = cfsetspeed(&settings,baudrate);
    if (rc!=0) {
      throw_ErrnoException("cfsetspeed("+fn+","
                         +boost::lexical_cast<std::string>(baudrate)+")");
    }
    rc = tcsetattr(fd, TCSANOW, &settings);
    if (rc<0) {
      throw_ErrnoException("tcsetattr("+fn+")");
    }
  }

  void discard_pending_input(void) {
    int rc = tcflush(fd, TCIFLUSH);
    if (rc!=0) {
      throw_ErrnoException("tcflush(TCIFLUSH)");
    }
  }


  typedef int modem_bits_t;

  modem_bits_t get_modem_bits(void) {
    modem_bits_t bits;
    ioctl(TIOCMGET,&bits);
    return bits;
  }

  bool is_cd(void) {
    return get_modem_bits()&TIOCM_CD;
  }

  bool is_ri(void) {
    return get_modem_bits()&TIOCM_RI;
  }

  bool is_dsr(void) {
    return get_modem_bits()&TIOCM_DSR;
  }

  bool is_cts(void) {
    return get_modem_bits()&TIOCM_CTS;
  }


  void set_these_modem_bits(modem_bits_t bits) {
    ioctl(TIOCMBIS,&bits);
  }

  void clear_these_modem_bits(modem_bits_t bits) {
    ioctl(TIOCMBIC,&bits);
  }

  void define_modem_bits(modem_bits_t bits, bool v) {
    if (v) {
      set_these_modem_bits(bits);
    } else {
      clear_these_modem_bits(bits);
    }
  }

  void define_rts(bool v) {
    define_modem_bits(TIOCM_RTS,v);
  }

  void define_dtr(bool v) {
    define_modem_bits(TIOCM_DTR,v);
  }

};

};

#endif
