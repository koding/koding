# src/Makefile
# This file is part of libpbe; see http://decimail.org
# (C) 2004-2007 Philip Endecott

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

LIBRARY=libpbe.a

library: $(LIBRARY)

UNAME_S=$(shell uname -s)
UNAME_R=$(shell uname -r)

ifeq (${UNAME_S},Linux)
  KVER=$(subst ., ,${UNAME_R})
  ifeq ($(word 1,${KVER}),2)
    ifeq ($(word 2,${KVER}),4)
      SUPPORT_LINUX_2_4=1
    endif
  endif
endif

#SRC_DIR=../src
#INCLUDE_DIR=../include
#SDK_ROOT:=../../..

VPATH=${SRC_DIR}

SKIP_SRCS:=

ifndef ENABLE_POSTGRESQL
  SKIP_SRCS+=Database.cc
endif

ifndef ENABLE_IMAGEMAGICK
  SKIP_SRCS+=jpegsize.cc
endif

ifndef ENABLE_RECODE
  SKIP_SRCS+=Recoder.cc
endif

ifdef DISABLE_HTTP_CLIENT
  SKIP_SRCS+=HttpClient.cc
endif

CC_SRCS=$(filter-out ${SKIP_SRCS},$(notdir $(wildcard ${SRC_DIR}/*.cc)))

CC_SRCS+=

OBJS=$(addsuffix .o,$(notdir $(basename $(CC_SRCS))))

DEPENDS=$(addsuffix .d,$(notdir $(basename $(CC_SRCS))))

-include $(DEPENDS)

WARN_FLAGS=-W -Wall

OPTIMISE_FLAGS=-O

DEBUG_FLAGS=

ifdef ENABLE_POSTGRESQL
  PG_INC_FLAGS=-I$(shell pg_config --includedir)
else
  PG_INC_FLAGS=
endif


INC_FLAGS+=$(PG_INC_FLAGS) -I${INCLUDE_DIR} -I$(SDK_ROOT)/include
COMPILE_FLAGS=$(WARN_FLAGS) $(OPTIMISE_FLAGS) $(DEBUG_FLAGS) $(INC_FLAGS) -pthread -fPIC

ifdef SUPPORT_LINUX_2_4
  COMPILE_FLAGS+=-DSUPPORT_LINUX_2_4
endif



$(LIBRARY): $(OBJS)
	$(AR) ruv $(LIBRARY) $(OBJS)

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(COMPILE_FLAGS) -c $<

%.d: %.cc
	$(CXX) $(CXXFLAGS) -pthread -MM -MT $@ -MT $(notdir $(<:%.cc=%.o)) $(INC_FLAGS) -o $@ $<

all: $(EXECUTABLE)

clean: FORCE
	$(RM) *.o $(LIBRARY)

veryclean: clean FORCE
	$(RM) *.d

FORCE:


testing:
	echo ${CC_SRCS}

