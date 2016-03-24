getPathInfo = require './getPathInfo'
nick = require './nick'
globals = require 'globals'

module.exports = (fullPath, secure = no) ->

  { machineUid, isPublic, path } = getPathInfo fullPath
  return unless isPublic
  pathPartials = path.match /^\/home\/(\w+)\/Web\/(.*)/
  return unless pathPartials
  [_, user, publicPath] = pathPartials

  publicPath or= ''
  domain = "#{machineUid}.#{nick()}.#{globals.config.userSitesDomain}"

  return "#{if secure then 'https' else 'http'}://#{domain}/#{publicPath}"
