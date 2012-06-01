// src/Recoder.hh
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
#ifndef libpbe_Recoder_hh
#define libpbe_Recoder_hh

#include <stdlib.h>
#include <stdio.h>
#include <recodext.h>

#include <string>

using namespace std;


class Recoder {

public:

  enum ErrorLevel { not_canonical=RECODE_NOT_CANONICAL,
		    ambiguous_output=RECODE_AMBIGUOUS_OUTPUT,
		    untranslatable=RECODE_UNTRANSLATABLE,
		    invalid_input=RECODE_INVALID_INPUT,
                    system_error=RECODE_SYSTEM_ERROR };

  Recoder(string from_charset, string to_charset,
	  ErrorLevel e=ambiguous_output);
  ~Recoder();
  string operator()(string i);
  string operator()(const char* i, int l);

private:

  ErrorLevel error_level;
  static RECODE_OUTER outer;
  RECODE_REQUEST request;

};


#endif
