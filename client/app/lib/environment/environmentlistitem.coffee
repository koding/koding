kd                     = require 'kd'
JView                  = require 'app/jview'
isKoding               = require 'app/util/isKoding'

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'

ComputeHelpers         = require '../providers/computehelpers'
ComputeController_UI   = require '../providers/computecontroller.ui'


module.exports = class EnvironmentListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environment-item', options.cssClass

    super options, data

    @createButtons()
    @createExtraViews()

    listView     = new MachinesList
    controller   = new MachinesListController
      view       : listView
      wrapper    : no
      scrollView : no
    ,
      items      : @getData().machines

    @machinesList = controller.getView()


  createButtons: ->

    @reinitButton     = new kd.CustomHTMLView cssClass: 'hidden'
    @addVMButton      = new kd.CustomHTMLView cssClass: 'hidden'
    @addManagedButton = new kd.CustomHTMLView cssClass: 'hidden'

    unless isKoding()
      @reinitButton = new kd.ButtonView
        cssClass    : 'solid compact red'
        title       : 'RE-INIT STACK'
        callback    : =>
          ComputeController_UI.askFor 'reinitStack', {}, =>
            @getDelegate().emit 'StackReinitRequested', @getData()

    if isKoding()
      @addVMButton = new kd.ButtonView
        title      : 'Add a Koding VM'
        cssClass   : 'add-vm-button solid green compact'
        callback   : => @handleMachineRequest 'koding'

    @addManagedButton = new kd.ButtonView
      title           : 'Add Your Own Machine'
      cssClass        : 'add-managed-button solid green compact'
      callback        : => @handleMachineRequest 'managed'


  handleMachineRequest: (provider) ->

      ComputeHelpers.handleNewMachineRequest { provider }
      @getDelegate().emit 'ModalDestroyRequested'


  createExtraViews: ->

    { group, stackRevision, _revisionStatus, machines, title } = @getData()


    @title = new kd.CustomHTMLView
      cssClass : 'stack-info clearfix hidden'
      partial  : "<div class='title'>#{title}</div>"

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


  pistachio: ->
    """
      {{> @title}}
      {{> @machinesList}}
      <div class="footer">
        <div class="icons">
          {{> @warningIcon}}
          {{> @infoIcon}}
        </div>
        <div class="button-container">
          {{> @reinitButton}}
          {{> @addManagedButton}}
          {{> @addVMButton}}
        </div>
      </div>
    """
