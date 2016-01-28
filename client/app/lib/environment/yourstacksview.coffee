kd                        = require 'kd'
whoami                    = require 'app/util/whoami'
isKoding                  = require 'app/util/isKoding'
showError                 = require 'app/util/showError'
checkFlag                 = require 'app/util/checkFlag'
StacksModal               = require 'app/stacks/stacksmodal'
EnvironmentList           = require './environmentlist'
KDCustomScrollView        = kd.CustomScrollView
EnvironmentListController = require './environmentlistcontroller'


module.exports = class YourStacksView extends KDCustomScrollView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environments-modal', options.cssClass
    options.width    = 772

    super options, data

    listView     = new EnvironmentList
    controller   = new EnvironmentListController
      view              : listView
      wrapper           : no
      selected          : options.selected
      scrollView        : no
      noItemFoundWidget : new kd.CustomHTMLView
        cssClass        : 'no-item-found'
        partial         : "You don't have any stacks."

    @wrapper.addSubView controller.getView()

    listView.on 'ModalDestroyRequested', @bound 'destroyModal'

    { computeController, appManager } = kd.singletons

    listView.on 'StackDeleteRequested', (stack) =>

      computeController.destroyStack stack, (err) =>
        return  if showError err

        new kd.NotificationView
          title : 'Stack deleted'

        computeController.reset yes
        @destroy()

    listView.on 'StackReinitRequested', (stack) =>

      computeController
        .once 'RenderStacks', @bound 'destroyModal'
        .reinitStack stack

    whoami().isEmailVerified (err, verified) ->
      if err or not verified
        for item in controller.getListItems()
          item.emit 'ManagedMachineIsNotAllowed'


  destroyModal: ->

    @getDelegate().parent.destroy()
