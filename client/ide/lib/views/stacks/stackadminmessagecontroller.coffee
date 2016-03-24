kd         = require 'kd'
IDEHelpers = require 'ide/idehelpers'
remote     = require('app/remote').getInstance()
showError  = require 'app/util/showError'

module.exports = class StackAdminMessageController extends kd.Controller

  constructor: ->

    super
    @banner = null


  showIfNeed: (machine) ->

    @banner.destroy()  if @banner
    return  unless machine

    { computeController } = kd.singletons

    stack = computeController.findStackFromMachineId machine._id
    return  unless stack

    remote.api.JComputeStack.one { _id : stack._id }, (err, _stack) =>
      return  unless _stack
      return  unless adminMessage = _stack.config?.adminMessage

      @showBanner { adminMessage, stack : _stack }


  showBanner: (data) ->

    { stack, adminMessage } = data
    { message, type }       = adminMessage
    { computeController }   = kd.singletons

    content = message
    if type is 'forcedReinit'
      content += ' Click <a href="#" class="reinit-stack-now">here</a> to re-init stack now.'
      hideCloseButton = yes
      click = (e) ->
        return  unless e.target.classList.contains 'reinit-stack-now'
        computeController.reinitStack stack
    else
      onClose = -> stack.deleteAdminMessage (err) -> showError err  if err

    @banner = IDEHelpers.showNotificationBanner {
      cssClass : 'stack-admin-message'
      content
      click
      hideCloseButton
      onClose
    }
    @banner.on 'KDObjectWillBeDestroyed', => @banner = null
