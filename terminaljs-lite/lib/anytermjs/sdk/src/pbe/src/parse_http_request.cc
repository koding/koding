// src/parse_http_request.cc
// This file is part of libpbe; see http://anyterm.org/
// (C) 2005-2008 Philip Endecott

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

#include "parse_http_request.hh"

#include <boost/spirit.hpp>
#include <boost/spirit/actor/insert_at_actor.hpp>
#include <boost/spirit/dynamic/if.hpp>
#include <boost/spirit/utility/loops.hpp>
#include <boost/spirit/iterator/multi_pass.hpp>

#include <boost/lexical_cast.hpp>
#include <boost/scoped_array.hpp>

#include <map>


using namespace std;
using namespace boost::spirit;


namespace pbe {


HttpRequest parse_http_request(istream& strm)
{
  HttpRequest request;

  typedef multi_pass<istreambuf_iterator<char> > iterator_t;
  typedef scanner<iterator_t> scanner_t;
  typedef rule<scanner_t> rule_t;

  string tmp_hn;
  string tmp_hv;

  // HTTP/1.1 request parsing, based on:
  //   RFC2616
  //   RFC2396
  //   HTTP/1.1 Errata (http://skrb.org/ietf/http_errata.html)

  rule_t CRLF = str_p("\r\n");

  rule_t extension_method = nothing_p;

  rule_t method = str_p("OPTIONS") | "GET" | "HEAD" | "POST" | "PUT"
    | "DELETE" | "TRACE" | "CONNECT" | extension_method;

  rule_t mark = ch_p('-') | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')';

  rule_t unreserved = alnum_p | mark;

  rule_t escaped = ch_p('%') >> xdigit_p >> xdigit_p;

  rule_t reserved = ch_p(';') | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ',';

  rule_t pchar = unreserved | escaped | ':' | '@' | '&' | '=' | '+' | '$' | ',';

  rule_t param = *pchar;

  rule_t segment = *pchar >> *(';' >> param);
  
  rule_t path_segments = segment >> *('/' >> segment);

  rule_t abs_path = ( ch_p('/') >> path_segments )[assign_a(request.abs_path)];

  rule_t scheme = alpha_p >> *(alpha_p | digit_p | '+' | '-' | '.' );

  rule_t userinfo = *(unreserved | escaped | ';' | ':' | '&' | '=' | '+' | '$' | ',' );

  rule_t domainlabel = alnum_p | alnum_p >> *(alnum_p | '-') >> alnum_p;

  rule_t toplabel = alpha_p | alpha_p >> *(alnum_p | '-') >> alnum_p;

  rule_t hostname = *(domainlabel >> '.') >> toplabel >> !ch_p('.');

  uint_parser<unsigned,10,1,3> decimal_byte;

  rule_t ipv4address = decimal_byte >> '.' >> decimal_byte >> '.' >> 
    decimal_byte >> '.' >> decimal_byte;

  rule_t host = hostname | ipv4address;

  rule_t port = uint_p;

  rule_t hostport = host >> !(':' >> port);

  rule_t server = !( !(userinfo >> '@') >> hostport );

  rule_t reg_name = +(unreserved | escaped | '$' | ',' | ';' | ':' | '@' |
		      '&' | '=' | '+');

  rule_t authority = server | reg_name;

  rule_t net_path = str_p("//") >> authority >> !abs_path;

  rule_t uric = reserved | unreserved | escaped;

  rule_t query = (*uric) [assign_a(request.query)];

  rule_t hier_part = (net_path | abs_path) >> !('?' >> query);

  rule_t uric_no_slash = unreserved | escaped | ';' | '?' | ':' | '@' |
    '&' | '=' | '+' | '$' | ',';

  rule_t opaque_part = uric_no_slash >> *uric;

  rule_t absolute_uri = scheme >> ':' >> (hier_part | opaque_part);
  
  rule_t request_uri = ch_p('*')
    | absolute_uri
    | (abs_path >> !(ch_p('?') >> query))
    | authority;

  rule_t http_version = str_p("HTTP/") >> uint_p >> '.' >> uint_p;

  rule_t request_line =
    method  [assign_a(request.method)]
    >> ' ' >> request_uri
    >> ' ' >> http_version [assign_a(request.http_version)]
    >> CRLF ;

  rule_t header_name = +(alnum_p|'-');

  rule_t header_value = *(print_p|' '|'\t');

  rule_t header = ( header_name [assign_a(tmp_hn)] >>
		    ':' >> *(ch_p(' ')) >> header_value [assign_a(tmp_hv)] )
    [insert_at_a(request.headers,tmp_hn,tmp_hv)];

  rule_t request_r =
    request_line
    >> *(header >> CRLF)
    >> CRLF;

  iterator_t first(make_multi_pass(std::istreambuf_iterator<char>(strm)));
  iterator_t last(make_multi_pass(std::istreambuf_iterator<char>()));

  scanner_t scanner(first,last);

  if (!request_r.parse(scanner)) {
    throw HttpRequestSyntaxError();
  }
  
  HttpRequest::headers_t::const_iterator i = request.headers.find("Content-Length");
  if (i==request.headers.end()) {
    return request;
  }
  size_t content_length = boost::lexical_cast<size_t>(i->second);
  boost::scoped_array<char> buf(new char[content_length]);
  strm.read(buf.get(),content_length);
  request.body = string(buf.get(),content_length);

  return request;
}


};

