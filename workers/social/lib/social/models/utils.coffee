KodingError = require '../error'
URL = require 'url'

SESSION_DATA_CORRUPTED = new KodingError 'Session data corrupted.'

module.exports =

  checkUserPassword: (account, password, callback) ->

    return callback 'Account not found'  unless account

    return callback 'Please provide password'  unless password

    account.fetchUser (err, user) ->
      return callback "Couldn't verify user"  if err

      unless user.checkPassword password
        return callback "Your password didn't match with our records"
      else
        callback()


  parseClient: (client) ->

    if not client or not client.context or not client.connection
      return { err: SESSION_DATA_CORRUPTED }

    group    = client.context.group
    username = client.connection.delegate?.profile?.nickname

    if not group or not username
      return { err: SESSION_DATA_CORRUPTED }

    return { group, username }


  cleanUrl: (url) ->

    url = URL.parse url
    url.query  = ''
    url.search = ''

    URL.format url


  isAddressValid: (addr, callback) ->

    ip  = require 'ip'
    dns = require 'dns'
    url = require 'url-parse'

    addr = url addr, true

    if ip.isV4Format _ip = addr.hostname
      return callback if ip.isPrivate _ip
      then {
        message: 'Private IPs not allowed'
        type: 'PRIVATE_IP'
      } else null

    dns.resolve addr.hostname, 'A', (err, ips) ->
      if err
        return callback {
          message: 'Address couldn\'t resolved'
          type: 'NOT_REACHABLE'
        }

      for _ip in ips when ip.isPrivate _ip
        return callback {
          message: 'Private IPs not allowed'
          type: 'PRIVATE_IP'
        }

      callback null
