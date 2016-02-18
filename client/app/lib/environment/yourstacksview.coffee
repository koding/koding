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

    options.cssClass    = kd.utils.curry 'environments-modal', options.cssClass
    options.width       = 772
    options.overlay    ?= yes

    super options, data

    listView     = new EnvironmentList
    controller   = new EnvironmentListController
      view              : listView
      wrapper           : no
      selected          : options.selected
      scrollView        : no
      noItemFoundWidget : new kd.CustomHTMLView
        cssClass        : 'no-item-found'
        partial         : "You don't have any #{if isKoding() then 'machines' else 'stacks'}."

    if checkFlag 'super-admin' and isKoding()

      advancedButton = new kd.ButtonView
        title    : 'ADVANCED'
        cssClass : 'compact solid green advanced'
        callback : -> new StacksModal

      # Hack to add button outside of modal container
      @addSubView advancedButton, '.kdmodal-inner'

    @wrapper.addSubView controller.getView()

    listView.on 'ModalDestroyRequested', @bound 'destroyModal'

    { computeController, appManager, router } = kd.singletons

    listView.on 'StackDeleteRequested', (stack) =>

      computeController.destroyStack stack, (err) =>
        return  if showError err

        new kd.NotificationView
          title : 'Stack deleted'

        computeController.reset yes, -> router.handleRoute '/IDE'
        @destroy()


    listView.on 'StackReinitRequested', (stack) =>
      computeController.once 'RenderStacks', => @destroyModal yes, yes

    whoami().isEmailVerified? (err, verified) ->
      if err or not verified
        for item in controller.getListItems()
          item.emit 'ManagedMachineIsNotAllowed'

    computeController.on 'RenderStacks', controller.bound 'loadItems'


  destroyModal: (goBack = yes, dontChangeRoute = no) ->

    return @emit 'DestroyParent', goBack  if isKoding()

    if modal = @getDelegate().parent
      modal.dontChangeRoute = dontChangeRoute
      modal.destroy()
