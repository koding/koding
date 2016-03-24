kd                     = require 'kd'
StackAdminMessageModal = require './stackadminmessagemodal'
showError              = require 'app/util/showError'
showNotification       = require 'app/util/showNotification'

module.exports = class ForceToReinitModal extends kd.ModalView

  DONE_MESSAGE   = 'Notification is sent'
  REINIT_MESSAGE = 'Please re-init your stack as soon as possible!'

  constructor: (options = {}, data) ->

    options.title   ?= 'Force to Re-init Stacks'
    options.content ?= '''
      If you choose to proceed, every outdated stack will show 
      a notification that it should be re-initialized. You can add 
      your personal message for that notification
    '''
    options.buttons  =
      proceed            :
        title            : 'Proceed'
        style            : 'solid red medium'
        loader           : yes
        callback         : @bound 'doProceed'
      proceedWithMessage :
        title            : 'Proceed with message'
        style            : 'solid red medium'
        loader           : yes
        callback         : @bound 'doProceedWithMessage'
      cancel             :
        title            : 'Cancel'
        style            : 'solid light-gray medium'
        callback         : @bound 'destroy'

    super options, data


  doProceed: ->

    @buttons.proceed.showLoader()

    stackTemplate = @getData()
    stackTemplate.forceStacksToReinit REINIT_MESSAGE, (err) =>
      if err
        @buttons.proceed.hideLoader()
        return showError err

      showNotification DONE_MESSAGE, { type : 'main' }
      @destroy()


  doProceedWithMessage: ->

    stackTemplate = @getData()
    new StackAdminMessageModal
      doneMessage : DONE_MESSAGE
      doneFn      : (message, callback) ->
        stackTemplate.forceStacksToReinit message, callback

    @destroy()
