kd                     = require 'kd'
JView                  = require 'app/jview'

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'


module.exports = class EnvironmentListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environment-item', options.cssClass
    super options, data

    { machines } = @getData()

    @reinitButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'REINIT'

    @terminateButton = new kd.ButtonView
      cssClass : 'solid compact outline red'
      title    : 'TERMINATE'

    @addVMButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'ADD VM'

    listView   = new MachinesList
    controller = new MachinesListController
      view       : listView
      wrapper    : no
      scrollView : no
    ,
      items      : machines

    @machinesList = controller.getView()



  pistachio: ->
    """
    <div class='stack-info clearfix'>
      {div.title{#(title)}}
      <div class='buttons'>
        {{> @reinitButton}}{{> @terminateButton}}{{> @addVMButton}}
      </div>
    </div>
    {{> @machinesList}}
    """
