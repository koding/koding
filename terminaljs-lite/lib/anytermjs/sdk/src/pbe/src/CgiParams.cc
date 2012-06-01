// src/CgiParams.cc
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

#include "CgiParams.hh"

#include "StringSplitter.hh"
#include "ci_string.hh"
#include "Exception.hh"
#include "utils.hh"

#include <boost/algorithm/string/trim.hpp>

#include <stdlib.h>
#include <unistd.h>

#ifdef __OpenBSD__
// Why is this needed?
#include <sys/types.h>
#endif

using namespace std;
using namespace pbe;


class CgiError: public Exception {
private:
  string msg;
public:
  CgiError(string m): msg(m) {}
  void report(ostream& s) const {
    s << "Error while decoding CGI input: " << msg << endl;
  }
};


static string uri_unescape(string esc)
{
  string unesc;
  string::size_type start=0;
  while(start<esc.size()) {
    string::size_type end=esc.find_first_of("%+",start);
    if (end==esc.npos) {
      unesc.append(esc,start,esc.size()-start);
      return unesc;
    }
    unesc.append(esc,start,(end-start));
    if (esc[end]=='+') {
      unesc+=' ';
      start=end+1;
    } else {
      unesc+=static_cast<char>(hex_string_to_int(esc.substr(end+1,2)));
      start=end+3;
    }
  }
  return unesc;
}


class MimeHeader {
private:
  ci_string name;
  string value;
  typedef map<ci_string,string> params_t;
  params_t params;
public:

  MimeHeader(string s)
  {
    const string::size_type colon_pos = s.find(':');
    if (colon_pos==s.npos) {
      throw CgiError("Malformed MIME header; no colon");
    }
    name = s.substr(0,colon_pos).c_str();
    const string value_and_params = s.substr(colon_pos+1);
    StringSplitterSeq splitter ( value_and_params, ";" );
    value = boost::algorithm::trim_copy(*splitter);
    ++splitter;
    while (!splitter.exhausted()) {
      const string param = *splitter;
      const unsigned int equals_pos = param.find('=');
      const ci_string pname = boost::algorithm::trim_copy(param.substr(0,equals_pos)).c_str();
      string pvalue = boost::algorithm::trim_copy(param.substr(equals_pos+1));
      if (pvalue[0]=='\"' && pvalue[pvalue.size()-1]=='\"') {
	pvalue=pvalue.substr(1,pvalue.size()-2);
      }
      params.insert(make_pair(pname,pvalue));
      ++splitter;
    }
  }

  ci_string get_name(void) const { return name; }
  string get_value(void) const { return value; }
  string get_param(ci_string name) const
  {
    params_t::const_iterator i = params.find(name);
    if (i==params.end()) {
      throw CgiError("No such header \""+string(name.c_str())+"\"");
    } else {
      return i->second;
    }
  }
};



void CgiParams::load(void)
{
  const char* method_c = getenv("REQUEST_METHOD");
  if (!method_c) {
    throw CgiError("REQUEST_METHOD not set");
  }
  const string method = method_c;

  // Normally you can assume that GET is accompanied with parameters
  // in the QUERY_STRING, while POST is accompanied with parameters in
  // the request body.  But I now sometimes use POST requests with
  // GET-style parameters and no body, so this code looks at the
  // QUERY_STRING in all cases, and does not reject an empty body.  If
  // it finds more than set of parameters they will be merged.

  const char* query_c = getenv("QUERY_STRING");
  if (query_c) {
    const string query = query_c;
    init_from_urlencoded(query);
  } else {
    if (method=="GET") {
      throw CgiError("QUERY_STRING not set in GET request");
    }
  }

  if (method=="POST") {
    
    // N.B. The CGI spec says that the server is not required to send EOF
    // after the POST data.  We should really look at the CONTENT_LENGTH
    // environment variable to find how much we should read.
    // (This does seem to work with Apache however.)
    string input;
    char buf[1024];
    int nr;
    do {
      nr = read(0,buf,sizeof(buf));
      input.append(buf,nr);
    } while (nr>0);

    const char* enctype_c = getenv("CONTENT_TYPE");
    if (!enctype_c) {
      return;
    }
    const string enctype = enctype_c;

    const MimeHeader enctype_hdr("content-type: "+enctype);

    if (enctype_hdr.get_value()=="application/x-www-form-urlencoded") {
      init_from_urlencoded(input);
    } else if (enctype_hdr.get_value()=="multipart/form-data") {
      const string boundary = enctype_hdr.get_param("boundary");
      init_from_multipart("\r\n"+input,boundary);
    } else {
      throw CgiError("Unknown content-type \""+enctype_hdr.get_value()+"\"");
    }
    
  }
}


void CgiParams::init_from_urlencoded(string query_string)
{
  if (query_string=="") {
    return;
  }
  for ( StringSplitterAny splitter ( query_string, "&;" );
	!splitter.exhausted(); ++splitter ) {
    string key_value = *splitter;
    string::size_type equals_pos = key_value.find('=');
    if (equals_pos==key_value.npos) {
      throw CgiError("Query string \""+query_string+"\" malformed");
    }
    string key_esc = key_value.substr(0,equals_pos);
    string key = uri_unescape(key_esc);
    string value_esc = key_value.substr(equals_pos+1);
    string value = uri_unescape(value_esc);
    insert(make_pair(key,value));
  }
}


void CgiParams::init_from_multipart(string input, string boundary)
{
  StringSplitterSeq splitter(input,"\r\n--"+boundary);
  ++splitter;

  while(!splitter.exhausted()) {
    const string pre_section = *splitter;
    if (pre_section.substr(0,2)=="--") {
      break;
    }

    unsigned int nl_pos = pre_section.find_first_not_of(" \t");
    if (pre_section.substr(nl_pos,2)!="\r\n") {
      throw CgiError("MIME boundary not followed by newline");
    }
    const string section = pre_section.substr(nl_pos+2);
    const string::size_type blank_line_pos = section.find("\r\n\r\n");
    if (blank_line_pos==section.npos) {
      throw CgiError("MIME section has no blank line");
    }
    const string header = section.substr(0,blank_line_pos);
    const string body = section.substr(blank_line_pos+4);
    
    string name="";

    for (StringSplitterSeq headersplit(header,"\r\n");
	 !headersplit.exhausted(); ++headersplit) {
      const string headerline = *headersplit;
      MimeHeader hdr(headerline);
      if (hdr.get_name()=="content-disposition") {
	if (hdr.get_value()=="form-data") {
	  name = hdr.get_param("name");
	}
      }
      if (hdr.get_name()=="content-transfer-encoding") {
	throw CgiError("Content transfer encodings are not supported");
      }
    }

    if (name=="") {
      throw CgiError("No name found");
    }

    insert(make_pair(name,body));
    ++splitter;
  }
}


string CgiParams::get(string name) const
{
  const_iterator i = find(name);
  if (i!=end()) {
    return i->second;
  } else {
    throw CgiError("Parameter "+name+" not found");
  }
}


string CgiParams::get_default(string name, string def) const
{
  const_iterator i = find(name);
  if (i!=end()) {
    return i->second;
  } else {
    return def;
  }
}

