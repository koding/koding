kd       = require 'kd'
globals  = require 'globals'
nick     = require 'app/util/nick'
FSHelper = require 'app/util/fs/fshelper'

module.exports =
  name         : 'Viewer'
  route        : '/:name?/Viewer'
  multiple     : yes
  openWith     : 'forceNew'
  behavior     : 'application'
  preCondition :
    condition  : (options, cb) ->
      { path, vmName } = options
      return cb true  unless path
      path = FSHelper.plainPath path
      publicPath = path.replace \
        ////home/(.*)/Web/(.*)///, "https://$1.#{globals.config.userSitesDomain}/$2"
      cb publicPath isnt path, { path: publicPath }
    failure    : (options, cb) ->
      correctPath = \
        "/home/#{nick()}/Web/"
      kd.getSingleton('appManager').notify "File must be under: #{correctPath}"
