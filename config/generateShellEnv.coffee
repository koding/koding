traverse  = require 'traverse'

module.exports.create = (KONFIG, options = {}) ->
  env = ''

  add = (name, value) ->
    env += "declare -p #{name} &> /dev/null || export #{name}=\"#{value}\"\n"

  traverse.paths(KONFIG).forEach (path) ->
    node = traverse.get KONFIG, path
    return  if typeof node is 'object'
    add "KONFIG_#{path.join('_').replace(/\./g, "_")}".toUpperCase(), node

  add 'ENV_JSON_FILE', '$(dirname ${BASH_SOURCE[0]})/$(basename ${BASH_SOURCE[0]} .sh).json'
  add 'KONFIG_JSON', '$(cat $ENV_JSON_FILE)'

  add 'KITE_HOME', '$KONFIG_KITEHOME'
  add 'GOPATH', '$KONFIG_PROJECTROOT/go'
  add 'GOBIN', '$GOPATH/bin'

  return env unless options.countlyPath

  # add this env vars if only countlyPath is set.
  add 'COUNTLY_PATH', '/countly'
  add 'COUNTLY_MONGODB_HOST', '$KONFIG_SERVICEHOST'
  add 'COUNTLY_MONGODB_DB', 'countly'
  add 'COUNTLY_MONGODB_PORT', '27017'

  return env
