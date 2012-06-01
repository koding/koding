// src/run_cmd.hh
// This file is part of libpbe; see http://decimail.org
// (C) 2005, 2007 Philip Endecott

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

#ifndef libpbe_run_cmd_hh
#define libpbe_run_cmd_hh

#include <string>


namespace pbe {

std::string run_cmd(std::string cmd, bool& exit_ok);

std::string run_cmd(std::string cmd);

};


#endif
