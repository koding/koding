globals      = require 'globals'
doXhrRequest = require 'app/util/doXhrRequest'

module.exports = class Proxifier

  @proxify = (options, callback) ->

    # take options for url
    { url, checkAlternatives } = options
    checkAlternatives         ?= yes

    # parse url
    parser = global.document.createElement 'a'
    parser.href = url

    # if url is already proxyfied return it as is
    proxyHost = "#{globals.config.userProxyHost}".replace '.', '\\.'
    return callback url  if ///#{proxyHost}///.test url
    return callback url  if parser.hostname in ['127.0.0.1', 'dev.kodi.ng']

    # if it's a tunnel given domain we need to do one more check
    # for tunnels since production tunnel proxy is different
    if (/\.koding\.me$/.test host = parser.hostname)

      baseURL = "#{globals.config.userTunnelUri}/#{host}"
      current = "//#{baseURL}#{parser.pathname}"

      return callback current  unless checkAlternatives

      Proxifier.checkAlternative baseURL, (err, res) ->

        if err
          console.warn '[tunnel] failed to look for alternatives:', err
          return callback current

        { protocol } = global.document.location

        # walk over alternatives for local and send
        # it back if found a match with the protocol
        for alt in res
          if ///^#{alt.protocol}///.test(protocol) and alt.local
            return callback "#{protocol}//#{alt.addr}/kite"

        callback current

    else
      callback "//#{globals.config.userProxyUri}/#{host}#{parser.pathname}"


  @checkAlternative = (baseURL, callback) ->

    endPoint = "#{baseURL}/-/discover/kite"
    type     = 'GET'
    timeout  = 2000

    doXhrRequest { endPoint, type, timeout }, callback
