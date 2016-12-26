{ extend } = require('underscore')

module.exports = (source, target) ->

  for own key of target
    source[key] ?= {}
    source[key] = extend source[key], target[key]

  return source
