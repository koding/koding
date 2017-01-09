kd                        = require 'kd'
whoami                    = require 'app/util/whoami'
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

    @wrapper.addSubView controller.getView()

    listView.on 'ModalDestroyRequested', @bound 'destroyModal'

    whoami().isEmailVerified? (err, verified) ->
      if err or not verified
        for item in controller.getListItems()
          item.emit 'ManagedMachineIsNotAllowed'


  destroyModal: (goBack = yes, dontChangeRoute = no) ->

    if modal = @getDelegate().parent
      modal.dontChangeRoute = dontChangeRoute
      modal.destroy()
