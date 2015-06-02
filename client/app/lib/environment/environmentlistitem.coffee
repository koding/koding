kd                     = require 'kd'
JView                  = require 'app/jview'
isKoding               = require 'app/util/isKoding'

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'


module.exports = class EnvironmentListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environment-item', options.cssClass
    super options, data

    { machines } = @getData()

    @reinitButton = new kd.ButtonView
      cssClass    : if isKoding() then 'hidden' else ''
      icon        : yes
      iconOnly    : yes
      iconClass   : 'reinit'


    @addVMButton  = new kd.ButtonView
      icon        : yes
      iconOnly    : yes
      iconClass   : 'add'

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
        {{> @reinitButton}}{{> @addVMButton}}
      </div>
    </div>
    {{> @machinesList}}
    """
