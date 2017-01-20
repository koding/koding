glob = require 'glob'
{ MANIFEST_FILE, CLIENT_PATH } = require '../constants'

MANIFESTS_GLOB = "*/#{MANIFEST_FILE}"

module.exports = getAppManifests = (options) ->

  defaultOptions =
    cwd: CLIENT_PATH
    realpath: yes

  options = Object.assign(defaultOptions, options)

  return glob.sync(MANIFESTS_GLOB, options).map(require)
