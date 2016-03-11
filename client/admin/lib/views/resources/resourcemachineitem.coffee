kd               = require 'kd'

showError        = require 'app/util/showError'
MachinesListItem = require 'app/environment/machineslistitem'
Machine          = require 'app/providers/machine'


module.exports   = class ResourceMachineItem extends MachinesListItem


  constructor: (options = {}, data) ->

    super options, data

    { computeController } = kd.singletons
    { uid, label } = machine = @getData()
    { stack } = @getOptions()

    mounted = !!(computeController.findMachineFromMachineId machine._id)

    @labelLink = new kd.CustomHTMLView
      cssClass : 'label-link'

    labelOptions = partial: label

    @labelLink.addSubView new kd.CustomHTMLView labelOptions

    { State } = Machine
    return  if machine.status.state in [
      State.NotInitialized
      State.Building
      State.Terminating
      State.Terminated
    ]

    @labelLink.addSubView new kd.ButtonView
      title    : if mounted then 'Mounted' else 'Mount'
      cssClass : 'solid mini green fl'
      loader   : yes
      disabled : mounted
      callback : ->

        mountButton = this

        notification = new kd.NotificationView
          title    : 'Mount in progress...'
          duration : 7000

        kloud = computeController.getKloud()
        kloud.addAdmin machineId: machine._id

          .then (shared) ->

            unless shared
              showError 'Failed to add admin into machine'
              mountButton.hideLoader()
              return

            stack.maintenance
              prepareForMount : yes
              machineId       : machine._id
            , (err) ->

              mountButton.hideLoader()
              notification.destroy()

              unless showError err
                new kd.NotificationView title: 'Mounted successfully'
                mountButton.setTitle 'Mounted'
                mountButton.disable()

          .catch (err) ->
            mountButton.hideLoader()
            notification.destroy()
            showError err, 'Failed to mount machine'


  createSidebarToggle: ->

    @sidebarToggle = new kd.CustomHTMLView

