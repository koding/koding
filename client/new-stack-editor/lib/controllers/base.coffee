kd = require 'kd'


module.exports = class BaseController extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    if editor = @getOption 'editor'
      @editor = editor

    if logs = @getOption 'logs'
      @logs = logs
