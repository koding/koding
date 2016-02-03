kd                      = require 'kd'
MyInitialView           = require './myinitialview'
BaseStackTemplatesView  = require '../basestacktemplatesview'


module.exports = class MyStackTemplatesView extends BaseStackTemplatesView


  constructor: (options = {}, data) ->

    options.initialView = new MyInitialView

    super options, data
