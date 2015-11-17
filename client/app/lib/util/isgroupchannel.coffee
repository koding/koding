getGroup = require 'app/util/getGroup'

module.exports = (channel) ->

  return channel.name is getGroup().slug

