# Arguments:
#
#  object      : an object
#
#  options     :
#    maxDepth  : maximum depth for object walk (default: 24)
#    separator : char to use depth separator   (default: \t)
#
# If fails, returns [Object object]
#

Encoder = require 'htmlencode'

module.exports = objectToString = (object, options = {}) ->

  { maxDepth, separator } = options

  maxDepth  ?= 24
  separator ?= '\t'

  stringify = ->

    depth  = 0
    ccache = []

    (key, value) ->

      return if depth > maxDepth
      return 'undefined'  unless value?

      depth++

      if typeof value is 'object'
        return  unless ccache.indexOf value is -1
        ccache.push value
      else
        value = value.toString()

      return value

  try
    s = (Encoder.htmlDecode JSON.stringify object, stringify(), separator).replace(/\\n/g, '\n')
  catch e
    console.warn 'Failed to stringify:', e, object
    s = '[Object object]'

  return s
