# Makefile
# This file is part of libpbe; see http://decimail.org
# (C) 2005-2007 Philip Endecott

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

default_target: library


ROOT_DIR=$(shell pwd)
#SDK_BUILD_DIR=$(ROOT_DIR)/../..
#BUILD_DIR=build

LIBRARY=libpbe.a

library: $(LIBRARY)

$(LIBRARY): FORCE
	${MAKE} -f $(ROOT_DIR)/common.mk ${LIBRARY} -C $(BUILD_DIR) SRC_DIR=$(ROOT_DIR)/src INCLUDE_DIR=$(ROOT_DIR)/include SDK_ROOT=$(SDK_ROOT)

clean: FORCE
	${MAKE} -f $(ROOT_DIR)/common.mk clean -C $(BUILD_DIR)
	rm $(LIBRARY)

veryclean: FORCE
	$(MAKE) -f $(ROOT_DIR)/common.mk veryclean

.PHONY: clean veryclean library default_target

FORCE:

