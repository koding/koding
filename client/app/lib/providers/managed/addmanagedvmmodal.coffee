kd   = require 'kd'
view = require './view'

INSTALL_INSTRUCTIONS = """bash
  $ curl -sO https://s3.amazonaws.com/koding-klient/install.sh
  $ bash ./install.sh
  # Enter your koding.com credentials when asked for
"""

class ManagedVMBaseModal extends kd.ModalView

  constructor: (options = {}, data) ->

    defaults   =
      width    : 640
      cssClass : 'managed-vm modal'

    options    = defaults extends options

    super options, data

    @addSubView @container = new kd.View

    @states  =
      initial: (data) =>
        view.addTo @container, message: 'Override this state first.'


  switchTo: (state, data)->

    @container.destroySubViews()

    state = 'initial'  unless @states[state]?
    stateFn = @states[state]
    stateFn data


  viewAppended: ->
    @switchTo 'initial'


module.exports = class AddManagedVMModal extends ManagedVMBaseModal

  constructor: ->
    super title: 'Add your own VM'

    @states  =

      initial: (data) =>

        view.addTo @container,
          instructions : INSTALL_INSTRUCTIONS
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
          instructions : INSTALL_INSTRUCTIONS
          retry        :
            text       : data
            callback   : @lazyBound 'switchTo', 'initial'


      listKites: (data) =>

        {list, button} = view.addTo @container,
          instructions : INSTALL_INSTRUCTIONS
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
