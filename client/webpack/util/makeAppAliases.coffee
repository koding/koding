path = require 'path'
{ CLIENT_PATH, APP_MAIN_FOLDER } = require '../constants'
getAppManifests = require './getAppManifests'

# This lets us omit the `lib` folders from require paths.
#
# No need to write
#    require '../../../home/lib/routehandler'
# We can just write
#    require 'home/routehandler'
module.exports = makeAppAliases = ->

  getAppManifests().reduce (res, manifest) ->
    res[manifest.name] = path.join CLIENT_PATH, manifest.name, APP_MAIN_FOLDER
    return res
  , {}
