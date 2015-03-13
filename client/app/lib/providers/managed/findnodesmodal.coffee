kd   = require 'kd'
view = require './view'
ManagedVMBaseModal = require './basemodal'

module.exports = class FindManagedNodesModal extends ManagedVMBaseModal

  constructor: (options, data)->

    super title: 'Search for available nodes'

    {@machine} = options

    @states    =

      initial: (data) =>

        view.addTo @container,
          waiting    : 'Checking for kite instances...'

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
