kd                        = require 'kd'
JView                     = require 'app/jview'

isKoding                  = require 'app/util/isKoding'
checkFlag                 = require 'app/util/checkFlag'
showError                 = require 'app/util/showError'
showNotification          = require 'app/util/showNotification'
isManagedVMStack          = require 'app/util/isManagedVMStack'
hasManagedVMStack         = require 'app/util/hasManagedVMStack'

remote                    = require('app/remote').getInstance()

MachinesList              = require './machineslist'
MachinesListController    = require './machineslistcontroller'

KodingSwitch              = require 'app/commonviews/kodingswitch'
ComputeHelpers            = require '../providers/computehelpers'
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

    @reinitButton         = new kd.CustomHTMLView cssClass: 'hidden'
    @addVMButton          = new kd.CustomHTMLView cssClass: 'hidden'
    @addManagedButton     = new kd.CustomHTMLView cssClass: 'hidden'
    @deleteStackButton    = new kd.CustomHTMLView cssClass: 'hidden'
    @addSoftlayerVMButton = new kd.CustomHTMLView cssClass: 'hidden'

    { title } = stack = @getData()

    unless isKoding() or title is 'Managed VMs'
      @reinitButton = new kd.ButtonView
        cssClass    : 'solid compact red'
        title       : 'RE-INIT STACK'
        callback    : @bound 'handleStackReinit'

      @deleteStackButton = new kd.ButtonView
        cssClass : 'solid compact red delete-stack'
        title    : 'Delete Stack'
        loader   : yes
        callback : @bound 'handleStackDelete'

    if isKoding()
      @addVMButton = new kd.ButtonView
        title      : 'Add a Koding VM'
        cssClass   : 'add-vm-button solid green compact'
        callback   : => @handleMachineRequest 'koding'

      if checkFlag 'softlayer'
        @addSoftlayerVMButton = new kd.ButtonView
          title      : 'Add a Softlayer VM'
          cssClass   : 'add-vm-button solid green compact'
          callback   : => @handleMachineRequest 'softlayer'

    if hasManagedVMStack()
      if isManagedVMStack stack
        @createManagedButton()
      else
        @addManagedButton = new kd.CustomHTMLView
    else
      @createManagedButton()


  createManagedButton: ->

    @addManagedButton = new kd.ButtonView
      title           : 'Add Your Own Machine'
      cssClass        : 'add-managed-button solid green compact'
      callback        : => @handleMachineRequest 'managed'


  handleStackReinit: ->

    @getDelegate().emit 'StackReinitRequested', @getData()


  handleStackDelete: ->

    @getDelegate().emit 'ModalDestroyRequested'

    { computeController } = kd.singletons
    computeController.ui.askFor 'deleteStack', {}, =>
      @getDelegate().emit 'StackDeleteRequested', @getData()


  handleMachineRequest: (provider) ->

    @getDelegate().emit 'ModalDestroyRequested'
    ComputeHelpers.handleNewMachineRequest { provider }


  createExtraViews: ->

    { title, config: { oldOwner } } = @getData()

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

    if oldOwner
      @header.addSubView new kd.CustomHTMLView
        tagName  : 'span'
        cssClass : 'old-owner-desc'
        partial  : """
          You have kicked @#{oldOwner} from your team, that's why all his resources are now assigned to you.
          You can delete their resources or keep it for backup purposes.
        """

    @updateNotification = new kd.CustomHTMLView
      cssClass : 'update-notification hidden'

    @stackStateToggle = new kd.CustomHTMLView
      cssClass : 'stack-state-toggle'

    if isKoding() or title is 'Managed VMs'
      @infoIcon = new kd.CustomHTMLView
    else
      @createInfoIcon()
      @createStackStateToggle()


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

  createStackStateToggle: ->

    { machines } = stack = @getData()
    { computeController, router } = kd.singletons

    notready     = no
    state        = no

    for machine in machines
      unless machine.isUsable()
        notready = yes
        state    = no
        break

      state |= machine.isRunning()

    toggle = new KodingSwitch
      cssClass      : 'tiny'
      defaultValue  : state
      disabled      : notready
      callback      : =>

        router.handleRoute '/IDE'

        if state
        then computeController.stopStack  stack
        else computeController.startStack stack

        @getDelegate().emit 'ModalDestroyRequested'

    if notready
      @stackStateToggle.setTooltip
        title : 'Machines are not ready'

    nextState = if state then 'off' else 'on'

    label = new kd.LabelView
      title     : "Turn #{nextState} all vms in this stack"
      mousedown : toggle.bound 'mouseDown'

    @stackStateToggle.addSubView toggle
    @stackStateToggle.addSubView label


  showUpdateNotification: ->

    @reinitButton.hide()

    @updateNotification.destroySubViews()

    @fetchStackTemplate (err, stackTemplate) =>

      return showNotification err  if err

      { template: { details } } = stackTemplate
      lastUpdaterId = details?.lastUpdaterId ? stackTemplate.originId

      remote.cacheable 'JAccount', lastUpdaterId, (err, account) =>

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
        {{> @stackStateToggle}}
        <div class="button-container">
          {{> @deleteStackButton}}
          {{> @reinitButton}}
          {{> @addManagedButton}}
          {{> @addSoftlayerVMButton}}
          {{> @addVMButton}}
        </div>
      </div>
    """
