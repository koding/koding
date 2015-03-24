kd   = require 'kd'
view = require './viewhelpers'
ManagedVMBaseModal = require './basemodal'
checkFlag = require 'app/util/checkFlag'

module.exports = class AddManagedVMModal extends ManagedVMBaseModal

  constructor: (options = {}, data)->

    return  unless checkFlag 'super-admin'

    hasContainer      = options.container?

    options           = kd.utils.extend options,
      title           : 'Add your own VM'
      cssClass        : 'add-managedvm'
      appendToDomBody : !hasContainer
      draggable       : no
      overlay         : !hasContainer

    super options, data

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

        {list, button_add,
         button_reload, message, loader} = view.addTo @container,
          instructions  : 'install'
          list          : { data }
          button_add    :
            title       : 'Use Selected Node'
            cssClass    : 'green'
            loader      : yes
            callback    : =>
              kite = list.controller.selectedItems.first.getData()
              if kite.machine
                message.show()
              else
                message.hide()
                @createMachine kite
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
            button_add.disable()
            message.hide()
          .on 'ItemSelectionPerformed', button_add.bound 'enable'


  createMachine: (kite)->

    {createMachine} = require './helpers'
    createMachine kite, (err, machine)=>

      showError = require 'app/util/showError'

      unless showError err

        kd.utils.defer ->
          kd.singletons.router.handleRoute "/IDE/#{machine.slug}"

        @destroy()
