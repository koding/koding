kd                     = require 'kd'
KDProgressBarView      = kd.ProgressBarView
JView                  = require 'app/jview'
Machine                = require 'app/providers/machine'
showError              = require 'app/util/showError'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
MachinesList           = require 'app/environment/machineslist'
ResourceMachineItem    = require './resourcemachineitem'
ResourceMachineHeader  = require './resourcemachineheader'
MachinesListController = require 'app/environment/machineslistcontroller'
StackAdminMessageModal = require 'app/stacks/stackadminmessagemodal'
async                  = require 'async'
whoami                 = require 'app/util/whoami'


module.exports = class ResourceListItem extends kd.ListItemView

  INITIAL_PROGRESS_VALUE = 10

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    isOwn     = data.originId is whoami()._id
    cssClass  = "resource-item clearfix #{data.status.state}"
    cssClass += ' own'  if isOwn

    options.type   or= 'member'
    options.cssClass = kd.utils.curry cssClass, options.cssClass

    super options, data

    resource = @getData()

    @detailsToggle = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Details <span class='settings-icon'></span>"
      click    : @getDelegate().lazyBound 'toggleDetails', this

    @details = new kd.CustomHTMLView
      cssClass : 'hidden details-container'

    listView          = new MachinesList
      itemClass       : ResourceMachineItem
      itemOptions     : { stack: resource }

    controller        = new MachinesListController
      view            : listView
      wrapper         : no
      scrollView      : no
      headerItemClass : ResourceMachineHeader
    ,
      items : (new Machine { machine } for machine in @getData().machines)

    @details.addSubView controller.getView()

    @details.addSubView new kd.ButtonView
      title    : 'Request Destroy'
      cssClass : 'solid small red fr'
      callback : @bound 'handleDestroy'

    @details.addSubView new kd.ButtonView
      title    : 'Delete'
      cssClass : 'solid small red fr'
      callback : @bound 'handleDelete'

    # temporary comment until stack admin message design is ready
    # @details.addSubView new kd.ButtonView
    #   title    : 'Admin Message'
    #   cssClass : 'solid small green fr'
    #   callback : @bound 'handleAdminMessage'

    @ownerView = new AvatarView {
      size: { width: 25, height: 25 }
    }, resource.owner

    @status = new kd.CustomHTMLView
      tagName  : 'span'
      partial  : resource.status.state

    @percentage = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'percentage'
    @updatePercentage()

    @progressBar = new KDProgressBarView { initial : INITIAL_PROGRESS_VALUE }

    { computeController } = kd.singletons
    computeController.on "apply-#{resource._id}", @bound 'handleProgressEvent'
    computeController.on "stateChanged-#{resource._id}", @bound 'handleStateChangedEvent'


  handleDestroy: ->

    resource              = @getData()
    { computeController } = kd.singletons

    queue = [
      (next) ->
        computeController.ui.askFor 'deleteStack', {}, (status) ->
          err = 'Not confirmed'  unless status.confirmed
          next err
      (next) ->
        resource.maintenance { prepareForDestroy: yes }, next
      (next) ->
        computeController.destroyStack resource, next
      (next) =>
        @setStatus 'Destroying'
        next()
    ]

    async.series queue, (err) =>
      return  if not err or err is 'Not confirmed'
      showError err
      @reload()


  handleDelete: ->

    resource              = @getData()
    delegate              = @getDelegate()
    { computeController } = kd.singletons

    computeController.ui.askFor 'forceDeleteStack', {}, (status) ->
      return  unless status.confirmed
      resource.maintenance { destroyStack: yes },  (err) ->
        @reload()  unless showError err


  handleAdminMessage: ->

    stack = @getData()
    new StackAdminMessageModal
      callback : (message, _callback) ->
        stack.createAdminMessage message, 'info', _callback


  toggleDetails: ->

    @details.toggleClass  'hidden'
    @detailsToggle.toggleClass 'active'
    @toggleClass 'in-detail'


  handleProgressEvent: (event) ->

    { percentage } = event
    @updatePercentage percentage
    @updateProgressBar percentage


  handleStateChangedEvent: (event) ->

    kd.utils.wait 100, @bound 'reload'


  setStatus: (state) ->

    resource = @getData()
    @unsetClass resource.status.state
    resource.status = { state }
    @setClass state

    @status.updatePartial state
    @updatePercentage()
    @updateProgressBar()


  updatePercentage: (percentage = INITIAL_PROGRESS_VALUE) ->

    @percentage.updatePartial ": #{percentage}%"


  updateProgressBar: (percentage = INITIAL_PROGRESS_VALUE) ->

    @progressBar.updateBar percentage


  reload: -> @getDelegate().emit 'ReloadItems'


  destroy: ->

    resource              = @getData()
    { computeController } = kd.singletons
    computeController.off "apply-#{resource._id}", @bound 'handleProgressEvent'
    computeController.off "stateChanged-#{resource._id}", @bound 'handleProgressEvent'

    super


  pistachio: ->

    """
      {{> @detailsToggle}}
      {{> @progressBar}}
      {{> @ownerView}}
      {div{#(title)}}
      <div class='status'>
        {{> @status}}
        {{> @percentage}}
      </div>
      <div class='clear'></div>
      {{> @details}}
    """
