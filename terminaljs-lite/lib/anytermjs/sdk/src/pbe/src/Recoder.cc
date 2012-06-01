// src/Recoder.cc
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
#include "Recoder.hh"

#include <stdlib.h>
#include <assert.h>

#include <iostream>


RECODE_OUTER Recoder::outer = NULL;

Recoder::Recoder(string from_charset, string to_charset, ErrorLevel e):
  error_level(e)
{
  if (!outer) {
    outer = recode_new_outer(false);
    assert(outer);
  }
  request = recode_new_request(outer);
  assert(request);
  assert(recode_scan_request(request,
			     string(from_charset+".."+to_charset).c_str()));
};


Recoder::~Recoder()
{
  recode_delete_request(request);
}


string Recoder::operator()(string i)
{
  return operator()(i.data(),i.size());
}


string Recoder::operator()(const char* i, int l)
{
  RECODE_TASK task = recode_new_task(request);

  task->input.name = NULL;
  task->input.file = NULL;
  task->input.buffer = i;
  task->input.cursor = i;
  task->input.limit = i+l;

  task->output.name = NULL;
  task->output.file = NULL;
  task->output.buffer = NULL;
  task->output.cursor = NULL;
  task->output.limit = NULL;

  task->fail_level = static_cast<enum recode_error>(error_level);

  assert(recode_perform_task(task));

  string o(task->output.buffer,task->output.cursor - task->output.buffer);
  free(task->output.buffer);

  recode_delete_task(task);

  return o;
}
