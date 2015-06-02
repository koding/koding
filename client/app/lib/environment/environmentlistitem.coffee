kd                     = require 'kd'
JView                  = require 'app/jview'
isKoding               = require 'app/util/isKoding'

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'

ComputeHelpers         = require '../providers/computehelpers'


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
      tooltip     :
        title     : 'Re-init Stack'

    {handleNewMachineRequest} = ComputeHelpers

    addVMMenu = if isKoding()
      'Create Koding VM':
        callback : =>
          handleNewMachineRequest
            provider: 'koding', @_menu.bound 'destroy'
    else
      'Add Your own VM':
        callback : =>
          handleNewMachineRequest
            provider: 'managed', @_menu.bound 'destroy'

    @addVMButton  = new kd.ButtonView
      icon        : yes
      iconOnly    : yes
      iconClass   : 'add'
      tooltip     :
        title     : 'Add new VM'
      callback    : =>
        @_menu = new kd.ContextMenu
          cssClass    : 'add-new-vm-menu'
          delegate    : @addVMButton
          y           : @addVMButton.getY() + 25
          x           : @addVMButton.getX() + @addVMButton.getWidth() / 2 - 120
          width       : 240
          arrow       :
            placement : 'top'
            margin    : -47
        , addVMMenu

    listView   = new MachinesList
    controller = new MachinesListController
      view        : listView
      wrapper     : no
      scrollView  : no
    ,
      items       : machines

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
