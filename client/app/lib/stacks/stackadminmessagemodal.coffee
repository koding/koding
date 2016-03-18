kd               = require 'kd'
showNotification = require 'app/util/showNotification'

module.exports = class StackAdminMessageModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.title       ?= 'Stack Admin Message'
    options.buttons      =
      send               :
        title            : 'Send'
        style            : 'solid green medium'
        callback         : @bound 'createMessage'
      cancel             :
        title            : 'Cancel'
        style            : 'solid light-gray medium'
        callback         : @bound 'destroy'
    options.doneMessage ?= 'Message is sent'
    options.view         = new kd.InputView
      type               : 'textarea'
      placeholder        : 'Enter your message here'

    super options, data


  createMessage: ->

    @buttons.send.showLoader()

    { stacks, type }      = @getData()
    { doneMessage, view } = @getOptions()
    { computeController } = kd.singletons

    message = this.getOption('view').getValue()
    computeController.ui.createAdminMessageForStacks stacks, message, type
    
    showNotification doneMessage, { type : 'main' }
    @destroy()
