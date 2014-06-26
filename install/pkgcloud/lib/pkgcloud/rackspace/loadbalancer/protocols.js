/*
 * protocols.js: Convenience object for LB protocols
 *
 * // TODO Move this into generalized helper section
 *
 * (C) 2013 Ken Perkins
 *
 * MIT LICENSE
 *
 */

exports.Protocols = {
  DNS_TCP: {
    "name": "DNS_TCP",
    "port": 53

  }, DNS_UDP: {
    "name": "DNS_UDP",
    "port": 53
  },
  FTP: {
    "name": "FTP",
    "port": 21
  },
  HTTP: {
    "name": "HTTP",
    "port": 80
  },
  HTTPS: {
    "name": "HTTPS",
    "port": 443
  },
  IMAPS: {
    "name": "IMAPS",
    "port": 993
  },
  IMAPv4: {
    "name": "IMAPv4",
    "port": 143
  },
  LDAP: {
    "name": "LDAP",
    "port": 389
  },
  LDAPS: {
    "name": "LDAPS",
    "port": 636
  },
  MYSQL: {
    "name": "MYSQL",
    "port": 3306
  },
  POP3: {
    "name": "POP3",
    "port": 110
  },
  POP3S: {
    "name": "POP3S",
    "port": 995
  },
  SMTP: {
    "name": "SMTP",
    "port": 25
  },
  TCP: {
    "name": "TCP",
    "port": 0
  },
  TCP_CLIENT_FIRST: {
    "name": "TCP_CLIENT_FIRST",
    "port": 0
  },
  UDP: {
    "name": "UDP",
    "port": 0
  },
  UDP_STREAM: {
    "name": "UDP_STREAM",
    "port": 0
  },
  SFTP: {
    "name": "SFTP",
    "port": 22
  }
};