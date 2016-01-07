jspath         = require 'jspath'
kd             = require 'kd'
KDEventEmitter = kd.EventEmitter

module.exports = class GroupData extends KDEventEmitter

  getAt: (path) -> jspath.getAt @data, path

  setGroup: (group) ->
    @data = group
    @emit 'update'
