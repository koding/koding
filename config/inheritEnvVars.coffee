traverse = require 'traverse'

module.exports = (KONFIG) ->

  traverse.forEach KONFIG, (node) ->
    return  if typeof node is 'object'

    if val = process.env["KONFIG_#{@path.join '_'}".toUpperCase()]
      try val = JSON.parse val

    return val or node
