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

        container       = view.addTo @container,
          instructions  : 'install'
          list          : { data }
          button_add    :
            title       : 'Use Selected Node'
            cssClass    : 'green'
            loader      : yes
            callback    : =>

              {message, list, button_add} = container

              kite = list.controller.selectedItems.first.getData()

              if kite.machine
                button_add.hideLoader()
                message.updatePartial 'This kite is in use.'
                message.show()
              else
                message.hide()
                @createMachine kite, container

          button_reload :
            iconOnly    : yes
            cssClass    : 'retry'
            callback    : =>

              {button_reload, message, loader} = container

              button_reload.hide()
              message.hide()
              loader.show()

              @fetchKites()

          loader        :
            cssClass    : 'inline'
          message       :
            text        : 'This kite is in use.'
            cssClass    : 'inline hidden'

        {list, button_add, message} = container

        list.controller
          .on 'ItemDeselectionPerformed', ->
            button_add.disable()
            message.hide()
          .on 'ItemSelectionPerformed', button_add.bound 'enable'


  createMachine: (kite, container)->

    {createMachine} = require './helpers'
    createMachine kite, (err, machine)=>

      showError = require 'app/util/showError'
      {message, button_add} = container

      if err

        if err.name is 'UsageLimitReached'
          message.updatePartial err.message
          message.show()
        else
          showError err

        button_add.hideLoader()

        return

      kd.utils.defer ->
        kd.singletons.router.handleRoute "/IDE/#{machine.slug}"

      @destroy()
