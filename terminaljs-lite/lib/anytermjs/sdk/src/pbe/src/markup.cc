// src/markup.cc
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
#include "markup.hh"

#include "StringTransformer.hh"

#include <regex.h>
#include <assert.h>


class AtDotToWords: public StringTransformer {
public:
  AtDotToWords() {
    add_cs_rule('@'," AT ");
    add_cs_rule('.'," DOT ");
  }
};

static AtDotToWords at_dot_to_words;


static string render_email(string e)
{
  string h = "<span class=\"ofsce\">"+at_dot_to_words(e)+"</span>";
  return h;
}


static string render_uri(string u)
{
  string uri;
  if (u.substr(0,4)!="http") {
    uri = "http://" + u;
  } else {
    uri=u;
  }
  string h = "<a href=\"";
  h += uri;
  h += "\">";
  h += u;
  h += "</a>";
  return h;
}


// See RFC2396 for URI syntax.

// We make the protocol prefix optional, so www.foo.com works.

// We require that the last component of the domain name is purely
// alphabetic and has at least two characters.  This is true in
// practice (.com, .uk) and helps to avoid false positives ("e.g.").

// We require that the last character of a path segment is not a
// common punctuation character: .!):;,  This is because
// these rarely fall at the end of a true URI but are often placed
// after a URI when it is written in text.

// We apply this after escaping & to &amp;.  This is only an issue in
// the path where ; normally has a special meaning which we have to
// ignore.

// We reuse the URI domain rules for emails.

// For email local parts we use the list of characters allowed by
// RFC2822, but allow adjacent .s.

// We disallow @ in URIs so that we can use it to distinguish emails
// from URIs.  They should be allowed in paths, queries and
// fragment-ids.


const char* uri_regexp =
"(https?://)?"  // optional protocol
"[-a-zA-Z0-9]+(\\.[-a-zA-Z0-9]+)*\\.[a-zA-Z][a-zA-Z]+"  // hostname
"(:[0-9]+)?"  // optional port number
"(/[-a-zA-Z0-9_.!~*'()%:&;=+$,]*[-a-zA-Z0-9_~*'(%&=+$])*"  // path, may be empty
"/?"  // path to directory may be terminated with a /
"(\\?[-;/?:&=+$,a-zA-Z0-9_.!~*'()]*)?"  // optional queery
"(#[-;/?:&=+$,a-zA-Z0-9_.!~*'()]*)?"  // optional fragment-id
;

const char* email_regexp =
"[a-zA-Z0-9!#$%&'*+-/=?^_`{|}~.]+"  // local-part
"@"
"[-a-zA-Z0-9]+(\\.[-a-zA-Z0-9]+)*\\.[a-zA-Z][a-zA-Z]+"  // hostname
;


void markup_uris_emails ( string& text )
{
  static bool re_compiled = false;
  static regex_t re;
  if (!re_compiled) {
    string regexp = string("(") + uri_regexp + ")|(" + email_regexp +")";
    int rc = regcomp(&re, regexp.c_str(), REG_EXTENDED);
    assert(rc==0);
    re_compiled=true;
  }

  string r;
  regmatch_t match;

  int pos=0;
  while (1) {
    int rc = regexec(&re, text.c_str()+pos, 1, &match, 0);
    assert((rc==0) || (rc==REG_NOMATCH));
    if (rc==REG_NOMATCH) {
      r.append(text.substr(pos));
      break;
    } 
    r += text.substr(pos,match.rm_so);
    string p = text.substr(pos+match.rm_so,match.rm_eo-match.rm_so);
    if (p.find('@')!=p.npos) {
      r += render_email(p);
    } else {
      r += render_uri(p);
    }
    pos += match.rm_eo;
  }

  text = r;
}
