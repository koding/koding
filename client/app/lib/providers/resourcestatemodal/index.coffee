kd = require 'kd'
StackFlowController = require './controllers/stackflowcontroller'
helpers = require './helpers'

module.exports = class ResourceStateModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'resource-state-modal', options.cssClass
    super options, data

    @stackFlow = new StackFlowController { container : this }, @getData()
    @forwardEvent @stackFlow, 'IDEBecameReady'


  updateStatus: (event, task) ->

    @stackFlow.updateStatus event, task


  destroy: ->

    @stackFlow.destroy()
    super
