kd                        = require 'kd'
React                     = require 'app/react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
KDReactorMixin            = require 'app/flux/base/reactormixin'
EnvironmentFlux           = require 'app/flux/environment'
StackUpdatedWidget        = require './stackupdatedwidget'
getBoundingClientReact    = require 'app/util/getBoundingClientReact'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'
remote = require 'app/remote'
isDefaultTeamStack = require 'app/util/isdefaultteamstack'
whoami = require 'app/util/whoami'
{ findDOMNode } = require 'react-dom'

require './styl/sidebarstacksection.styl'
require './styl/sidebarstackwidgets.styl'

MENU = null

module.exports = class SidebarStackSection extends React.Component

  @defaultProps =
    stack       : immutable.Map()


  constructor: ->

    super

    @state        =
      coordinates :
        left      : 0
        top       : 0
      showWidget  : no


  getDataBindings: ->

    selectedTemplateId: EnvironmentFlux.getters.selectedTemplateId
    groupStackTemplates: EnvironmentFlux.getters.teamStackTemplatesStore


  componentWillReceiveProps: (nextProps) ->

    nextStackUnreadCount = @getStackUnreadCount nextProps.stack
    @setState { showWidget : yes }  if nextStackUnreadCount > @getStackUnreadCount()

    @setCoordinates()


  componentDidMount: -> @setCoordinates()


  setCoordinates: ->

    return  unless @refs.sidebarSection

    coordinates = getBoundingClientReact @refs.sidebarSection
    @setState { coordinates: coordinates }


  renderMachines: ->

    config = @props.stack.get 'config'

    @props.stack.get('machines')
      .sort (a, b) -> a.get('label').localeCompare(b.get('label')) # Sorting from a to z
      .map (machine) =>
        visible = config?.getIn [ 'sidebar', machine.get('uid'), 'visibility' ]
        <SidebarMachinesListItem
          key={machine.get '_id'}
          stack={@props.stack}
          machine={machine}
          showInSidebar={visible}
          />


  onMenuItemClick: (item, event) ->

    { appManager, router, linkController, computeController } = kd.singletons
    { stack } = @props
    { reinitStackFromWidget, deleteStack } = EnvironmentFlux.actions

    { title } = item.getData()
    MENU.destroy()

    _id = stack.get 'baseStackId'


    switch title
      when 'Edit', 'View Stack' then router.handleRoute "/Stack-Editor/#{_id}"
      when 'Reinitialize', 'Update'
        reinitStackFromWidget(stack).then ->
          # invalidate editor cache
          appManager.tell 'Stackeditor', 'reloadEditor', _id
      when 'Clone'
        remote.api.JStackTemplate.one { _id }, (err, template) =>
          return @showErrorMessage 'Error occured while cloning template'  if err
          EnvironmentFlux.actions.cloneStackTemplate template, (err) =>
            return @showErrorMessage 'Error occured while cloning template'  if err
            return @showErrorMessage 'Your stack template successfully cloned'
      when 'Destroy VMs' then deleteStack { stack }
      when 'VMs' then router.handleRoute "/Home/stacks/virtual-machines"
      when 'Open on GitLab'
        remoteUrl = stack.getIn ['config', 'remoteDetails', 'originalUrl']
        linkController.openOrFocus remoteUrl
      when 'Make Team Default'
        remote.api.JStackTemplate.one { _id }, (err, template) =>
          return @showErrorMessage 'Error occured while making this stack team default'  if err
          EnvironmentFlux.actions.makeTeamDefault template, (err) =>
            return @showErrorMessage 'Error occured while making this stack team default'  if err
            return @showErrorMessage 'Your stack is team default now.'

      when 'Share Stack With Team'
        remote.api.JStackTemplate.one { _id }, (err, template) =>
          return @showErrorMessage 'Error occured while sharing stack with team'  if err
          EnvironmentFlux.actions.shareWithTeam template, (err) =>
            return @showErrorMessage 'Error occured while sharing stack with team'  if err
            return @showErrorMessage 'Your stack successfully shared with team'
      when 'Make Stack Private'
        remote.api.JStackTemplate.one { _id }, (err, template) =>
          return @showErrorMessage 'Error occured while unsharing this stack'  if err
          EnvironmentFlux.actions.makePrivate template, (err) =>
            return @showErrorMessage 'Error occured while unsharing this stack'  if err
            return @showErrorMessage 'Your stack is private now.'


  showErrorMessage: (title) -> new kd.NotificationView { title }


  onTitleClick: (event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if MENU

    callback = @bound 'onMenuItemClick'

    menuItems = {}

    if @getStackUnreadCount()
      menuItems['Update'] = { callback }

    if @props.stack.getIn ['config', 'remoteDetails', 'originalUrl']
      menuItems['Open on GitLab'] = { callback }

    managedVM = @props.stack.get('title').indexOf('Managed VMs') > -1

    baseStackId = @props.stack.get 'baseStackId'
    originId = @props.stack.get 'originId'

    if managedVM
      menuItems['VMs'] = { callback }
    else if @props.stack.get 'disabled'
      # because of disabled stack's baseTemplate came undefined
      # no need to show Edit, Clone, Reinitialize options
      ['VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }
    else
      if isAdmin() or @props.stack.get('accessLevel') is 'private'
        menuItems['Edit'] = { callback }
        menuItems['Clone'] = { callback }  if canCreateStacks()
      else
        menuItems['View Stack'] = { callback }
      ['Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }

      if isAdmin() and not isDefaultTeamStack baseStackId
        menuItems['Make Team Default'] = { callback }
        if baseStackId in Object.keys(@state.groupStackTemplates.toJS())
          menuItems['Make Stack Private'] = { callback }
        else
          menuItems['Share Stack With Team'] = { callback }



    { top } = findDOMNode(this).getBoundingClientRect()

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: top + 31 }

    MENU = new kd.ContextMenu menuOptions, menuItems

    MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> MENU = null


  renderStackUpdatedWidget: ->

    { coordinates, showWidget } = @state

    return null  unless @getStackUnreadCount()
    return null  if not coordinates.left and coordinates.top


    coordinates =
      left : coordinates.left + 6
      top : coordinates.top - 2

    <StackUpdatedWidget
      coordinates={coordinates}
      stack={@props.stack}
      visible={showWidget}
      onClose={@bound 'onWidgetClose'}
    />


  unreadCountClickHandler: ->

    @setState { showWidget: yes }


  onWidgetClose: ->

    @setState { showWidget: no }


  getStackUnreadCount: (stack = @props.stack) ->

    stack?.getIn [ '_revisionStatus', 'status', 'code' ]


  render: ->

    return null  unless @props.stack.get('machines').length

    className  = 'SidebarStackSection'
    className += ' active'  if @state.selectedTemplateId is @props.stack.get 'baseStackId'


    <SidebarSection
      ref='sidebarSection'
      className={kd.utils.curry className, @props.className}
      title={@props.stack.get 'title'}
      onTitleClick={@bound 'onTitleClick'}
      secondaryLink=''
      unreadCount={@getStackUnreadCount()}
      unreadCountClickHandler={@bound 'unreadCountClickHandler'}
      >
      {@renderMachines()}
      {@renderStackUpdatedWidget()}
    </SidebarSection>

isStackMine = (stackOriginId, myId) -> stackOriginId is myId


React.Component.include.call SidebarStackSection, [KDReactorMixin]
