globals      = require 'globals'
doXhrRequest = require 'app/util/doXhrRequest'

module.exports = (url, callback) ->

  # parse url
  parser = global.document.createElement 'a'
  parser.href = url

  # if url is already proxyfied return it as is
  return callback url  if /p\.koding\.com/.test url
  return callback url  if parser.hostname in ['127.0.0.1', 'dev.kodi.ng']

  # check if running under production environment
  isInProduction = globals.config.environment is 'production'

  # get the current protocol
  { protocol } = global.document.location

  # build our new url, example:
  # old: http://54.164.174.218:3000/kite
  # new: https://koding.com/-/prodproxy/54.164.243.111/kite
  #           or
  #      http://localhost:8090/-/prodproxy/54.164.243.111/kite

  # subdomain is for different proxy environments
  # one for development the other for production
  subdomain = if isInProduction then 'p' else 'dev-p'

  # create the base url
  baseURL = "#{protocol}//#{subdomain}.koding.com/-"

  # if it's a tunnel given domain we need to do one more check
  # for tunnels since production tunnel proxy is different
  if /\.koding\.me$/.test host = parser.hostname

    # for tunneled connections default tunnel is `devtunnel`
    proxy = if isInProduction then 'prodtunnel' else 'devtunnel'

    endPoint = "#{baseURL}/#{proxy}/#{host}/-/discover/kite"
    type     = 'GET'

    current  = "#{baseURL}/#{proxy}/#{host}#{parser.pathname}"

    doXhrRequest { endPoint, type }, (err, res) ->
      return callback current  if err

      for alt in res
        if ///^#{alt.protocol}///.test protocol
          return callback "#{protocol}//#{alt.addr}/kite"

      callback current

    # for now return the url as-is in dev environment
    # return callback url  if globals.config.environment is 'dev'

  # proxy support for not tunneled direct connections for each environment
  else

    proxy = if isInProduction then 'prodproxy' else 'devproxy'

    # generated proxyfied url for connecting to kite
    callback "#{baseURL}/#{proxy}/#{host}#{parser.pathname}"
