globals      = require 'globals'
doXhrRequest = require 'app/util/doXhrRequest'

module.exports = (url, callback) ->

  # if url is already proxyfied return it as is
  return callback url  if /p\.koding\.com/.test url

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

  # parse url
  parser = global.document.createElement 'a'
  parser.href = url

  # if it's a tunnel given domain we need to do one more check
  # for tunnels since production tunnel proxy is different
  if /\.koding\.me$/.test host = parser.hostname

    # for tunneled connections default tunnel is `devtunnel`
    proxy = if isInProduction then 'prodtunnel' else 'devtunnel'

    # for now return the url as-is in dev environment
    return callback url  if globals.config.environment is 'dev'

  # proxy support for not tunneled direct connections for each environment
  else

    proxy = if isInProduction then 'prodproxy' else 'devproxy'

  # generated proxyfied url for connecting to kite
  callback "#{protocol}//#{subdomain}.koding.com/-/#{proxy}/#{parser.hostname}#{parser.pathname}"
