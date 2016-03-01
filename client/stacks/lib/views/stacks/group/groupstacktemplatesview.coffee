GroupInitialView       = require './groupinitialview'
BaseStackTemplatesView = require '../basestacktemplatesview'


module.exports = class GroupStackTemplatesView extends BaseStackTemplatesView


  constructor: (options = {}, data) ->

    options.initialView = new GroupInitialView

    super options, data
