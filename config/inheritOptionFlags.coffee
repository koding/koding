traverse = require 'traverse'

module.exports = (credentials, options) ->
  options_list = paths(options)
  credentials_list = paths(credentials)

  for i, val of options_list
    if traverse.has(credentials, val)
      traverse(credentials).set(val, traverse.get(options, val))

paths = (obj) ->
  result = []
  traverse.forEach obj, (x) ->
    result.push @path if typeof x isnt 'object'
    return
  result
