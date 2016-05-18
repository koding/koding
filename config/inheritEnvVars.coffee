traverse = require 'traverse'

module.exports = (KONFIG) ->

  traverse.forEach (node) ->
    node = traverse.get KONFIG, path
    return  if typeof node is 'object'

    if val = process.env["KONFIG_#{@path.join '_'}"]
      try val = JSON.parse val

    return val or node
