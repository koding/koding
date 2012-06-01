// src/CgiVars.hh
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

#ifndef libpbe_CgiVars_hh
#define libpbe_CgiVars_hh

#include <map>
#include <string>

class CgiVars: public std::map<std::string,std::string> {
private:
  void setvar(const char* varname);
  std::string get(std::string varname) const {
    CgiVars::const_iterator i = find(varname);
    if (i==end()) {
      return "";
    } else {
      return i->second;
    }
  }

public:
  void load(void);

  // Basic variables defined by CGI spec:
  std::string get_server_software(void)    const { return get("SERVER_SOFTWARE"); }
  std::string get_server_name(void)        const { return get("SERVER_NAME"); }
  std::string get_gateway_interface(void)  const { return get("GATEWAY_INTERFACE"); }
  std::string get_server_protocol(void)    const { return get("SERVER_PROTOCOL"); }
  std::string get_server_port(void)        const { return get("SERVER_PORT"); }
  std::string get_request_method(void)     const { return get("REQUEST_METHOD"); }
  std::string get_path_info(void)          const { return get("PATH_INFO"); }
  std::string get_path_translated(void)    const { return get("PATH_TRANSLATED"); }
  std::string get_script_name(void)        const { return get("SCRIPT_NAME"); }
  std::string get_query_string(void)       const { return get("QUERY_STRING"); }
  std::string get_remote_host(void)        const { return get("REMOTE_HOST"); }
  std::string get_auth_type(void)          const { return get("AUTH_TYPE"); }
  std::string get_remote_user(void)        const { return get("REMOTE_USER"); }
  std::string get_remote_ident(void)       const { return get("REMOTE_IDENT"); }
  std::string get_content_type(void)       const { return get("CONTENT_TYPE"); }
  std::string get_content_length(void)     const { return get("CONTENT_LENGTH"); }

  // Generic HTTP variables:
  std::string get_http_user_agent(void)    const { return get("HTTP_USER_AGENT"); }
  std::string get_http_cookie(void)        const { return get("HTTP_COOKIE"); }
  std::string get_http_if_modified_since(void)
                                      const { return get("HTTP_IF_MODIFIED_SINCE"); }
  std::string get_http_if_none_match(void) const { return get("HTTP_IF_NONE_MATCH"); }

  // Apache specials:
  bool get_https(void)                const { return get("HTTPS")!=""; }

  static const CgiVars& singleton(void);
};


#endif
