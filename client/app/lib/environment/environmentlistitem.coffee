kd                     = require 'kd'
JView                  = require 'app/jview'
isKoding               = require 'app/util/isKoding'

remote                 = require('app/remote').getInstance()

MachinesList           = require './machineslist'
MachinesListController = require './machineslistcontroller'

ComputeHelpers         = require '../providers/computehelpers'

showNotification       = require 'app/util/showNotification'

StackTemplateContentModal = require 'app/stacks/stacktemplatecontentmodal'


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

    { title } = @getData()

    unless isKoding() or title is 'Managed VMs'
      @reinitButton = new kd.ButtonView
        cssClass    : 'solid compact red'
        title       : 'RE-INIT STACK'
        callback    : @bound 'handleStackReinit'

    if isKoding()
      @addVMButton = new kd.ButtonView
        title      : 'Add a Koding VM'
        cssClass   : 'add-vm-button solid green compact'
        callback   : => @handleMachineRequest 'koding'

    @addManagedButton = new kd.ButtonView
      title           : 'Add Your Own Machine'
      cssClass        : 'add-managed-button solid green compact'
      callback        : => @handleMachineRequest 'managed'


  handleStackReinit: ->

    { ui } = kd.singletons.computeController

    ui.askFor 'reinitStack', {}, =>
      @getDelegate().emit 'StackReinitRequested', @getData()


  handleMachineRequest: (provider) ->

      @getDelegate().emit 'ModalDestroyRequested'
      ComputeHelpers.handleNewMachineRequest { provider }


  createExtraViews: ->

    { title } = @getData()

    @header = new kd.CustomHTMLView
      cssClass : 'stack-info clearfix hidden'
      click    : @lazyBound 'toggleClass', 'collapsed'

    @header.addSubView new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'arrow'

    @header.addSubView new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'title'
      partial  : title

    @updateNotification = new kd.CustomHTMLView
      cssClass : 'update-notification hidden'

    if isKoding() or title is 'Managed VMs'
    then @infoIcon = new kd.CustomHTMLView
    else @createInfoIcon()


  createInfoIcon: ->

    { group, stackRevision, _revisionStatus, machines } = @getData()

    if _revisionStatus?.status? and _revisionStatus.status.code > 0
      @showUpdateNotification()
      revisionMessage = ''
    else
      revisionMessage = "You're currently using the latest revision."

    @infoIcon     = new kd.CustomHTMLView
      cssClass    : 'info-icon'
      click       : @bound 'showStackTemplateContent'
      tooltip     :
        placement : 'right'
        cssClass  : 'info-tooltip'
        title     : "
          This stack is provided by #{group}. It
          includes #{machines.length} machines and generated
          from #{stackRevision[..5]} revision. <br/>
          #{revisionMessage}
        "


  showUpdateNotification: ->

    @reinitButton.hide()

    @updateNotification.destroySubViews()

    @fetchStackTemplate (err, template) =>

      return showNotification err  if err

      remote.cacheable 'JAccount', template.originId, (err, account) =>

        @updateNotification.addSubView description = new kd.CustomHTMLView
          tagName  : 'div'
          cssClass : 'description'

        description.addSubView new kd.CustomHTMLView
          tagName  : 'span'
          partial  : "#{account.profile.firstName} has updated this stack"

        description.addSubView new kd.CustomHTMLView
          tagName  : 'span'
          partial  : ' (<a href="#">see details</a>).'
          click    : @bound 'showStackTemplateContent'

        @updateNotification.addSubView new kd.ButtonView
          title    : 'Update Your Machines'
          cssClass : 'reinit-stack solid green compact'
          callback : @bound 'handleStackReinit'

        @updateNotification.show()


  fetchStackTemplate: (callback) ->

    { computeController } = kd.singletons

    computeController.fetchBaseStackTemplate @getData(), callback


  showStackTemplateContent: ->

    @fetchStackTemplate (err, template) ->

      return showNotification err  if err

      new StackTemplateContentModal {}, template


  pistachio: ->
    """
      {{> @header}}
      {{> @machinesList}}
      {{> @updateNotification}}
      <div class="footer">
        <div class="icons">
          {{> @infoIcon}}
        </div>
        <div class="button-container">
          {{> @reinitButton}}
          {{> @addManagedButton}}
          {{> @addVMButton}}
        </div>
      </div>
    """
