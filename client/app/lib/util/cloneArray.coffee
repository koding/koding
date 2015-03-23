_ = require 'underscore'

clone          =
module.exports =

(arr) ->

  if _.isArray arr
    return _.map arr, clone
  else if 'object' is typeof arr
    throw 'array should not contain an object'
  else
    return arr