kd                     = require 'kd'
JView                  = require 'app/jview'
Machine                = require 'app/providers/machine'
showError              = require 'app/util/showError'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
MachinesList           = require 'app/environment/machineslist'
ResourceMachineItem    = require './resourcemachineitem'
ResourceMachineHeader  = require './resourcemachineheader'
MachinesListController = require 'app/environment/machineslistcontroller'


module.exports = class ResourceListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type   or= 'member'
    options.cssClass = kd.utils.curry "resource-item clearfix", options.cssClass

    super options, data

    @detailsToggle = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Details <span class='settings-icon'></span>"
      click    : @getDelegate().lazyBound 'toggleDetails', this

    resource = @getData()

    @details = new kd.CustomHTMLView
      cssClass : 'hidden'

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

    @ownerView = new AvatarView {
      size: { width: 25, height: 25 }
    }, resource.owner


  handleDestroy: ->

    resource              = @getData()
    delegate              = @getDelegate()
    { computeController } = kd.singletons

    computeController.ui.askFor 'deleteStack', {}, (status) ->
      return  unless status.confirmed

      resource.maintenance prepareForDestroy: yes, (err) ->
        return  if showError err

        computeController.destroyStack resource, (err) ->
          return  if showError err

          # FIXME ~GG this reload mechanism needs to be
          #           replaced with auto instance update instead
          delegate.emit 'ReloadItems'
          computeController.once "stateChanged-#{resource._id}", ->
            delegate.emit 'ReloadItems'


  handleDelete: ->

    resource              = @getData()
    delegate              = @getDelegate()
    { computeController } = kd.singletons

    computeController.ui.askFor 'forceDeleteStack', {}, (status) ->
      return  unless status.confirmed
      resource.maintenance destroyStack: yes,  (err) ->
        delegate.emit 'ReloadItems'  unless showError err


  toggleDetails: ->

    @details.toggleClass  'hidden'
    @detailsToggle.toggleClass 'active'
    @toggleClass 'in-detail'


  pistachio: ->

    """
      {{> @detailsToggle}}
      {{> @ownerView}}
      {div.details{#(title)}}
      {div.status{#(status.state)}}
      <div class='clear'></div>
      {{> @details}}
    """
