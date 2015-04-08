globals = require 'globals'
_ = require 'lodash'

SEPARATOR   = '+'
MAC_UNICODE =
  shift   : '&#x21E7;'
  command : '&#x2318;'
  alt     : '&#x2325;'
  ctrl    : '^'

convertCase = _.capitalize
render = _.template '<% _.forEach(keys, function (key) { %><span><%= key %></span><% }) %>'

module.exports = (str) ->

  keys = str.split SEPARATOR

  render keys:
    if globals.os isnt 'mac'
    then _.map keys, (value) -> convertCase value
    else _.map keys, (value) -> MAC_UNICODE[value] or convertCase value
