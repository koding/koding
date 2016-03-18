whoami = require './whoami'

module.exports = ->
  whoami()?.type is 'registered'
