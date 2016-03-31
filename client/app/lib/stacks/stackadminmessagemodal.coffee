kd               = require 'kd'
showNotification = require 'app/util/showNotification'
showError        = require 'app/util/showError'

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

    { doneMessage, callback, view } = @getOptions()

    message = view.getValue()
    callback message, (err) =>
      @buttons.send.hideLoader()

      return showError err  if err
    
      showNotification doneMessage, { type : 'main' }
      @destroy()
