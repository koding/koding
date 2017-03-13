kd         = require 'kd'
IDEHelpers = require 'ide/idehelpers'
remote     = require 'app/remote'
showError  = require 'app/util/showError'

module.exports = class StackAdminMessageController extends kd.Controller

  constructor: (options) ->

    super options

    @banner = null

    { computeController } = kd.singletons
    computeController.on 'StackAdminMessageReceived', @bound 'showIfNeeded'


  showIfNeeded: ->

    { machine } = @getOptions()
    return  unless machine

    { computeController } = kd.singletons
    computeController.ready =>
      stack = computeController.findStackFromMachineId machine._id
      return  unless stack
      return  unless adminMessage = stack.config?.adminMessage

      { message, type } = adminMessage
      @showBanner stack, message, type


  showBanner: (stack, message, type) ->

    @banner.destroy()  if @banner

    { computeController } = kd.singletons
    { container }         = @getOptions()

    content = message
    if type is 'forcedReinit'
      content += ' Click <a href="#" class="reinit-stack-now">here</a> to re-init stack now.'
      hideCloseButton = yes
      click = (e) ->
        return  unless e.target.classList.contains 'reinit-stack-now'
        computeController.reinitStack stack
    else
      onClose = @lazyBound 'handleDeleteAdminMessage', stack

    @banner = IDEHelpers.showNotificationBanner {
      cssClass : 'stack-admin-message'
      container
      content
      click
      hideCloseButton
      onClose
    }
    @banner.on 'KDObjectWillBeDestroyed', => @banner = null


  handleDeleteAdminMessage: (stack) ->

    { computeController } = kd.singletons
    stack.deleteAdminMessage (err) ->
      showError err  if err
      computeController.emit 'StackAdminMessageDeleted', stack._id
