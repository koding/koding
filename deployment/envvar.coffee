traverse  = require 'traverse'

module.exports.create = (KONFIG) ->
  conf = ''

  append = (name, value) ->
    conf += "export #{name}=${#{name}:-'#{value}'}\n"

  traverse.paths(KONFIG).forEach (path) ->
    return  unless node = traverse.get KONFIG, path

    switch typeof node
      when 'object'
        if node.hasOwnProperty 'toString'
        then val = node.toString()
        else return
      when 'function' then return

    varName  = "KONFIG_#{path.join('_')}".toUpperCase()
    varValue = process.env[varName] or val or node
    append varName, varValue

  append 'KITE_HOME', '${KITE_HOME:-$KONFIG_KITEHOME}'

  return conf
