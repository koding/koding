kd = require 'kd'

module.exports = EventEmitter =

  on: kd.EventEmitter::on
  off: kd.EventEmitter::off
  emit: kd.EventEmitter::emit

  componentDidMount: ->
    @id = kd.utils.getUniqueId()
    kd.EventEmitter.call this
