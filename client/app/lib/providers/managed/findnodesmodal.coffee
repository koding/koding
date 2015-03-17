kd   = require 'kd'
view = require './view'
ManagedVMBaseModal = require './basemodal'

module.exports = class FindManagedNodesModal extends ManagedVMBaseModal

  constructor: (options = {}, data)->

    hasContainer      = options.container?

    defaults          =
      title           : 'Search for available nodes'
      cssClass        : 'find-nodes'
      appendToDomBody : !hasContainer
      draggable       : !hasContainer

    options           = defaults extends options

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

        {list, button} = view.addTo @container,
          text         : "
            We are unable to reach your managed vm, but we found following
            klients registered with your account.
          ", 'warning'
          list         : { data }
          button       :
            title      : 'Delete Managed VM'
            callback   : =>
              console.log 'Will be implemented'
          button       :
            title      : 'Assign Selected Node'
            disabled   : yes
            callback   : =>
              @assignKite list.controller.selectedItems.first.getData()

        list.controller.on 'ItemSelectionPerformed', button.bound 'enable'


  assignKite: (kite)->

    console.log 'assign will be implemented', kite
