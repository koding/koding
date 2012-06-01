// src/select.hh
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
#ifndef libpbe_select_hh
#define libpbe_select_hh

// User-friendly wrappers around select().
// Take various numbers of file descriptors and an optional timeout.
// Naming scheme is "r" for "readable", "t" for "timeout".
// i.e. select_rr waits for either of two fds to be readable.
// The return value is the file descriptor that has become useable,
// i.e. select_rr(4,9) can return 4 or 9.  If the timeout expires,
// -1 is returned.  -2 can also be returned but I can't recall when.

int select_r (int fd1);
int select_rr(int fd1, int fd2);
int select_rt(int fd1, float timeout);


#endif
