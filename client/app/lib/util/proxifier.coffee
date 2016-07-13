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
    baseDomain = "#{globals.config.domains.base}".replace '.', '\\.'
    return callback url  if ///p\.#{baseDomain}///.test url
    return callback url  if parser.hostname in ['127.0.0.1', 'dev.kodi.ng']

    # check if running under production environment
    isInProduction = @isInProduction()

    # get the current protocol
    protocol = @getProtocol()

    # build our new url, example:
    # old: http://54.164.174.218:3000/kite
    # new: https://p.koding.com/-/prodproxy/54.164.243.111/kite
    #           or
    #      http://localhost:8090/-/prodproxy/54.164.243.111/kite

    # subdomain is for different proxy environments
    # one for development the other for production
    subdomain = if isInProduction then 'p' else 'dev-p2'

    # create the base url
    # Since proxy is a service from koding.com we need to use it
    # for on-premise version as well. otherwise all the on-premises
    # users needs to run proxy server on their own ~GG
    baseURL = "#{protocol}//#{subdomain}.koding.com/-"
    # baseURL = "#{protocol}//#{subdomain}.#{globals.config.domains.base}/-"

    # if it's a tunnel given domain we need to do one more check
    # for tunnels since production tunnel proxy is different
    if (/\.koding\.me$/.test host = parser.hostname)

      # for tunneled connections default tunnel is `devtunnel`
      proxy    = if isInProduction then 'prodtunnel' else 'devtunnel'
      baseURL  = "#{baseURL}/#{proxy}/#{host}"
      current  = "#{baseURL}#{parser.pathname}"

      return callback current  unless checkAlternatives

      Proxifier.checkAlternative protocol, baseURL, (err, res) ->

        if err
          console.warn '[tunnel] failed to look for alternatives:', err
          return callback current

        # walk over alternatives for local and send
        # it back if found a match with the protocol
        for alt in res
          if ///^#{alt.protocol}///.test(protocol) and alt.local
            return callback "#{protocol}//#{alt.addr}/kite"

        callback current

    # proxy support for not tunneled direct connections for each environment
    else

      proxy = if isInProduction then 'prodproxy' else 'devproxy'

      # generated proxyfied url for connecting to kite
      callback "#{baseURL}/#{proxy}/#{host}#{parser.pathname}"


  @checkAlternative = (protocol, baseURL, callback) ->

    endPoint = "#{baseURL}/-/discover/kite"
    type     = 'GET'
    timeout  = 2000

    doXhrRequest { endPoint, type, timeout }, callback


  @getProtocol = ->
    { protocol } = global.document.location
    return protocol


  @isInProduction = ->
    return globals.config.environment is 'production'
