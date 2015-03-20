kd   = require 'kd'
view = require './view'
showError = require 'app/util/showError'
ManagedVMBaseModal = require './basemodal'

module.exports = class FindManagedNodesModal extends ManagedVMBaseModal

  constructor: (options = {}, data)->

    hasContainer      = options.container?

    options           = kd.utils.extend options,
      title           : 'Search for available nodes'
      cssClass        : 'find-nodes'
      appendToDomBody : !hasContainer
      draggable       : no
      overlay         : !hasContainer

    if options.reassign
      options.title  ?= "Use different kite for machine #{data.label}"

    super options, data

    @machine = @getData()
    @states  =

      initial: (data) =>

        view.addTo @container,
          instructions : 'install'
          waiting      : 'Checking for kite instances...'

        @fetchKites()


      retry: (data) =>

        view.addTo @container,
          instructions : 'install'
          retry        :
            text       : data
            callback   : @lazyBound 'switchTo', 'initial'


      listKites: (data) =>

        {loader, message, list,
         button_assign, button_reload} = view.addTo @container,
          message_warn  :
            text        : "We are unable to reach your managed vm
                          (#{@machine.ipAddress}), but we've found following
                          klient kites registered with your account."
            cssClass    : "warning #{if @getOption 'reassign' then 'hidden'}"
          list          : { data }
          button_assign :
            title       : 'Use Selected Kite'
            cssClass    : 'green'
            callback    : =>
              kite = list.controller.selectedItems.first.getData()
              if kite.machine
                message.show()
              else
                message.hide()
                @assignKite kite
          button_delete :
            title       : 'Delete VM'
            cssClass    : "red #{if @getOption 'reassign' then 'hidden'}"
            callback    : @bound 'removeMachine'
          button_reload :
            iconOnly    : yes
            cssClass    : 'retry'
            callback    : =>
              button_reload.hide()
              message.hide()
              loader.show()
              @fetchKites()
          loader        :
            cssClass    : 'inline'
          message       :
            text        : 'This kite is in use.'
            cssClass    : 'inline hidden'

        list.controller

          .on 'ItemDeselectionPerformed', ->
            button_assign.disable()
            message.hide()

          .on 'ItemSelectionPerformed', button_assign.bound 'enable'


    if container = @getOption 'container'
      kd.utils.defer => container.addSubView this


  assignKite: (kite)->

    {updateMachineData} = require './helpers'

    @machine.getBaseKite(createIfNotExists = no).disconnect()

    updateMachineData {@machine, kite}, (err)=>
      return if showError err

      {computeController, appManager} = kd.singletons
      environmentDataProvider = require 'app/userenvironmentdataprovider'
      environmentDataProvider.fetch =>
        @machine.getBaseKite().connect()
        appManager.tell 'IDE', 'quit'
        @destroy()


  removeMachine: ->

    kd.singletons.computeController.destroy @machine
