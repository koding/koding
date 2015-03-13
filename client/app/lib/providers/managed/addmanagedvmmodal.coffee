kd   = require 'kd'
view = require './view'
ManagedVMBaseModal = require './basemodal'

module.exports = class AddManagedVMModal extends ManagedVMBaseModal

  constructor: ->
    super title: 'Add your own VM'

    @states  =

      initial: (data) =>

        view.addTo @container,
          instructions : 'install'
          waiting      : 'Checking for kite instances...'

        {queryKites} = require './helpers'

        queryKites()
          .then (result) =>
            if result?.kites?.length
            then @switchTo 'listKites', result.kites
            else @switchTo 'retry', 'No kite instance found'
          .catch (err) =>
            console.warn "Error:", err
            @switchTo 'retry', 'Failed to query kites'


      retry: (data) =>

        view.addTo @container,
          instructions : 'install'
          retry        :
            text       : data
            callback   : @lazyBound 'switchTo', 'initial'


      listKites: (data) =>

        {list, button} = view.addTo @container,
          instructions : 'install'
          list         : { data }
          button       :
            title      : 'Add Selected Node'
            disabled   : yes
            callback   : =>
              @createMachine list.controller.selectedItems.first.getData()

        list.controller.on 'ItemSelectionPerformed', button.bound 'enable'


  createMachine: (kite)->

    {createMachine} = require './helpers'
    createMachine kite, (err, machine)=>

      showError = require 'app/util/showError'

      unless showError err

        kd.utils.defer ->
          kd.singletons.router.handleRoute "/IDE/#{machine.slug}"

        @destroy()
