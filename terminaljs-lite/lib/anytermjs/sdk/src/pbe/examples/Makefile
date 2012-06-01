# examples/Makefile
# This file is part of libpbe; see http://decimail.org
# (C) 2007 Philip Endecott

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

default_target: all

all: inc_daemon mailform directory_explorer fixed_point

DEBUG_FLAGS=-W -Wall
OPT_FLAGS=-O
INC_FLAGS=-I../include
LINK_FLAGS=-L.. -lpbe

CPP=g++
CPP_FLAGS=$(DEBUG_FLAGS) $(OPT_FLAGS) $(INC_FLAGS)


%: %.cc
	$(CPP) $(CPP_FLAGS) $< -o $@ $(LINK_FLAGS)


inc_daemon: inc_daemon.cc
	$(CPP) $(CPP_FLAGS) $< -o $@ $(LINK_FLAGS) -lomnithread

mailform: mailform.cc

directory_explorer: directory_explorer.cc

bunzip http_get_bunzip: LINK_FLAGS+=-lbz2
gunzip http_get_gunzip http_get_with_etag: LINK_FLAGS+=-lz

.PHONY: default_target all
