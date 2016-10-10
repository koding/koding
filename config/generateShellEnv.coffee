traverse  = require 'traverse'

module.exports.create = (KONFIG, options = {}) ->
  env = ''

  add = (name, value) ->
    # Escape $ sign when it precedes lower-case character which means that this
    # is not a bash variable but nginx one.
    value = (value.replace /(\$)[a-z0-9]/g, (match) -> "\\#{match}") if typeof value is 'string'

    env += "export #{name}=${#{name}:-#{value}}\n"

  traverse.paths(KONFIG).forEach (path) ->
    node = traverse.get KONFIG, path
    return  if typeof node is 'object'
    add "KONFIG_#{path.join('_')}".toUpperCase(), node

  add 'ENV_JSON_FILE', "$KONFIG_PROJECTROOT/#{options.envFileName}.json"
  add 'KONFIG_JSON', '$(cat $ENV_JSON_FILE)'

  add 'KITE_HOME', '$KONFIG_KITEHOME'
  add 'GOPATH', '$KONFIG_PROJECTROOT/go'
  add 'GOBIN', '$GOPATH/bin'

  return env
