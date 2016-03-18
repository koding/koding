kd         = require 'kd'
IDEHelpers = require 'ide/idehelpers'

module.exports = class StackAdminMessageController extends kd.Controller

  constructor: ->

    super
    @banner = null


  showIfNeed: (machine) ->

    @banner.destroy()  if @banner
    return  unless machine

    { computeController } = kd.singletons
    computeController.fetchStackByMachineId machine._id, (err, stack) =>
      return  unless stack
      return  unless adminMessage = stack.config?.adminMessage

      @showBanner { adminMessage, stack }


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
      onClose = -> computeController.ui.deleteStackAdminMessage stack

    @banner = IDEHelpers.showNotificationBanner {
      cssClass : 'stack-admin-message'
      content
      click
      hideCloseButton
      onClose
    }
    @banner.on 'KDObjectWillBeDestroyed', => @banner = null
