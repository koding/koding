// src/URI.cc
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

#include "URI.hh"

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


URI::URI(string absolute_uri):
  port(0)
{
  typedef rule<> rule_t;

  // URI parsing EBNF based on
  //   RFC2616
  //   RFC2396
  //   HTTP/1.1 Errata (http://skrb.org/ietf/http_errata.html)

  rule_t mark = ch_p('-') | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')';

  rule_t unreserved = alnum_p | mark;

  rule_t escaped = ch_p('%') >> xdigit_p >> xdigit_p;

  rule_t reserved = ch_p(';') | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ',';

  rule_t pchar = unreserved | escaped | ':' | '@' | '&' | '=' | '+' | '$' | ',';

  rule_t param = *pchar;

  rule_t segment = *pchar >> *(';' >> param);
  
  rule_t path_segments = segment >> *('/' >> segment);

  rule_t abs_path = ( ch_p('/') >> path_segments )[assign_a(URI::abs_path)];

  rule_t scheme = alpha_p >> *(alpha_p | digit_p | '+' | '-' | '.' );

  rule_t userinfo = *(unreserved | escaped | ';' | ':' | '&' | '=' | '+' | '$' | ',' );

  //rule_t domainlabel = alnum_p | alnum_p >> *(alnum_p | '-') >> alnum_p;
  rule_t domainlabel = *(alnum_p | '-');

  //rule_t toplabel = alpha_p | alpha_p >> *(alnum_p | '-') >> alnum_p;

  //rule_t hostname = *(domainlabel >> '.') >> toplabel >> !ch_p('.');
  rule_t hostname = domainlabel % ch_p('.');

  uint_parser<unsigned,10,1,3> decimal_byte;

  rule_t ipv4address = decimal_byte >> '.' >> decimal_byte >> '.' >> 
    decimal_byte >> '.' >> decimal_byte;

  rule_t host = hostname | ipv4address;

  rule_t port = uint_p[assign_a(URI::port)];

  rule_t hostport = host[assign_a(URI::host)]
                    >> !(':' >> port);

  rule_t server = !( !(userinfo[assign_a(URI::userinfo)] >> '@') >> hostport );

  rule_t reg_name = +(unreserved | escaped | '$' | ',' | ';' | ':' | '@' |
		      '&' | '=' | '+');

  rule_t authority = server | reg_name;

  rule_t net_path = str_p("//") >> authority >> !abs_path;

  rule_t uric = reserved | unreserved | escaped;

  rule_t query = (*uric) [assign_a(URI::query)];

  rule_t hier_part = (net_path | abs_path) >> !('?' >> query);

  rule_t uric_no_slash = unreserved | escaped | ';' | '?' | ':' | '@' |
    '&' | '=' | '+' | '$' | ',';

  rule_t opaque_part = uric_no_slash >> *uric;

  rule_t absoluteURI = scheme[assign_a(URI::scheme)] >> ':' >> (hier_part | opaque_part);
  
  if (!parse(absolute_uri.c_str(), absoluteURI).full) {
    throw SyntaxError();
  }
}


};

