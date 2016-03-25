kd                        = require 'kd'
whoami                    = require 'app/util/whoami'
isKoding                  = require 'app/util/isKoding'
showError                 = require 'app/util/showError'
checkFlag                 = require 'app/util/checkFlag'
StacksModal               = require 'app/stacks/stacksmodal'
KDCustomScrollView        = kd.CustomScrollView
EnvironmentListController = require './environmentlistcontroller'


module.exports = class YourStacksView extends KDCustomScrollView


  constructor: (options = {}, data) ->

    options.cssClass    = kd.utils.curry 'environments-modal', options.cssClass
    options.width       = 772
    options.overlay    ?= yes

    super options, data

    controller  = new EnvironmentListController { selected : options.selected }
    listView    = controller.getListView()

    if checkFlag 'super-admin' and isKoding()

      advancedButton = new kd.ButtonView
        title    : 'ADVANCED'
        cssClass : 'compact solid green advanced'
        callback : -> new StacksModal

      # Hack to add button outside of modal container
      @addSubView advancedButton, '.kdmodal-inner'

    @wrapper.addSubView controller.getView()

    listView.on 'ModalDestroyRequested', @bound 'destroyModal'
    listView.on 'DestroyYourStacksView', @bound 'destroy'

    whoami().isEmailVerified? (err, verified) ->
      if err or not verified
        for item in controller.getListItems()
          item.emit 'ManagedMachineIsNotAllowed'


  destroyModal: (goBack = yes, dontChangeRoute = no) ->

    return @emit 'DestroyParent', goBack  if isKoding()

    if modal = @getDelegate().parent
      modal.dontChangeRoute = dontChangeRoute
      modal.destroy()
