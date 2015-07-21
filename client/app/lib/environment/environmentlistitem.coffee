kd                     = require 'kd'
JView                  = require 'app/jview'
isKoding               = require 'app/util/isKoding'
checkFlag              = require 'app/util/checkFlag'

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'

ComputeHelpers         = require '../providers/computehelpers'
ComputeController_UI   = require '../providers/computecontroller.ui'


module.exports = class EnvironmentListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environment-item', options.cssClass

    super options, data

    { machines, _revisionStatus } = stack = @getData()
    delegate = @getDelegate()

    @reinitButton = new kd.ButtonView
      cssClass    : if isKoding() then 'hidden' else ''
      icon        : yes
      iconOnly    : yes
      iconClass   : 'reinit'
      tooltip     :
        title     : 'Re-init Stack'
      callback    : ->
        ComputeController_UI.askFor 'reinitStack', {}, ->
          delegate.emit 'StackReinitRequested', stack

    addVMMenu = {}

    if isKoding()
      addVMMenu['Create Koding VM'] = callback: @generateMenuCallback 'koding'

    if checkFlag ['super-admin', 'super-digitalocean']
      addVMMenu['Add Your Own Machine']  = callback: @generateMenuCallback 'managed'


    @addVMButton  = new kd.ButtonView
      icon        : yes
      iconOnly    : yes
      iconClass   : 'add'
      cssClass    : 'add-vm-button'
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

    @warningIcon = new kd.CustomHTMLView
      cssClass   : 'warning-icon hidden'
      tooltip    :
        title    : """Base stack template has been updated, please
                      re-init this stack to get latest changes."""

    if _revisionStatus?.status? and _revisionStatus.status.code > 0
      @warningIcon.show()
      revisionMessage = ''
    else
      revisionMessage = "You're currently using the latest revision."

    {group, stackRevision} = stack
    @infoIcon     = new kd.CustomHTMLView
      cssClass    : 'info-icon'
      tooltip     :
        placement : 'right'
        cssClass  : 'info-tooltip'
        title     : "
          This stack is provided by #{group}. It
          includes #{machines.length} machines and generated
          from #{stackRevision[..5]} revision. <br/>
          #{revisionMessage}
        "

    @infoIcon.hide()  if isKoding()

    listView   = new MachinesList
    controller = new MachinesListController
      view        : listView
      wrapper     : no
      scrollView  : no
    ,
      items       : machines

    @machinesList = controller.getView()


  generateMenuCallback: (provider) ->

    {handleNewMachineRequest} = ComputeHelpers
    delegate = @getDelegate()

    return =>
      handleNewMachineRequest { provider }
      @_menu.destroy()
      delegate.emit 'ModalDestroyRequested'


  pistachio: ->
    """
    <div class='stack-info clearfix'>
      {{> @warningIcon}} {div.title{#(title)}} {{> @infoIcon}}
      <div class='buttons'>
        {{> @reinitButton}}{{> @addVMButton}}
      </div>
    </div>
    {{> @machinesList}}
    """
