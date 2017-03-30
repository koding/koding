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
{ findDOMNode } = require 'react-dom'
whoami = require 'app/util/whoami'

debug = require('debug')('sidebar:stacksection')

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


  componentWillReceiveProps: (nextProps) ->

    nextStackUnreadCount = @getStackUnreadCount nextProps.stack

    debug 'will show widget or not',
      currentUnreadCount: @getStackUnreadCount()
      nextUnreadCount: nextStackUnreadCount

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

    templateId = stack.get 'baseStackId'


    switch title
      when 'Edit', 'View Stack' then router.handleRoute "/Stack-Editor/#{templateId}"
      when 'Reinitialize', 'Update'
        reinitStackFromWidget(stack).then ->
          # invalidate editor cache
          appManager.tell 'Stackeditor', 'reloadEditor', templateId
      when 'Clone'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'cloning'  if err
          EnvironmentFlux.actions.cloneStackTemplate template  if template
      when 'Destroy VMs' then deleteStack { stack }
      when 'VMs'
        firstMachineId = stack.get('machines').first.get '_id'
        router.handleRoute "/Home/stacks/virtual-machines/#{firstMachineId}"
      when 'Open on GitLab'
        remoteUrl = stack.getIn ['config', 'remoteDetails', 'originalUrl']
        linkController.openOrFocus remoteUrl
      when 'Make Team Default'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'making team default'  if err

          computeController.makeTeamDefault template  if template
      when 'Share With Team'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'sharing'  if err
          if template
            computeController.setStackTemplateAccessLevel template, 'group'
      when 'Make Private'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'cloning'  if err

          if template
            computeController.setStackTemplateAccessLevel template, 'private'



  onMenuItemClickError: (name) ->

    return new kd.NotificationView { title: "Error occured while #{name} template" }

  onTitleClick: (event) ->

    id = @props.stack.get 'baseStackId'
    kd.singletons.router.handleRoute "/Stack-Editor/#{id}"


  onMenuIconClick: (event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if MENU

    callback = @bound 'onMenuItemClick'
    menuItems = {}

    { template, stack } = @props
    { storage } = kd.singletons.computeController

    template = template.toJS()
    stack = stack.toJS()
    account = whoami()

    isMyTemplate = template?.originId is account._id

    debug 'accessLevel', template.accessLevel

    if @getStackUnreadCount()
      menuItems['Update'] = { callback }

    if stack.config?.remoteDetails?.originalUrl?
      menuItems['Open on GitLab'] = { callback }

    if stack.title.indexOf('Managed VMs') > -1
      menuItems['VMs'] = { callback }

    else if stack.disabled
      # because of disabled stack's baseTemplate came undefined
      # no need to show Edit, Clone, Reinitialize options
      ['VMs', 'Destroy VMs'].forEach (name) -> menuItems[name] = { callback }

    else

      if isAdmin() or isMyTemplate
        menuItems['Edit'] = { callback }

        if canCreateStacks()
          menuItems['Clone'] = { callback }

      else
        menuItems['View Stack'] = { callback }

      ['Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }

      if isAdmin() and not isDefaultTeamStack stack.baseStackId
        menuItems['Make Team Default'] = { callback }

      if isMyTemplate and not isDefaultTeamStack stack.baseStackId

        if template.accessLevel is 'private'
          menuItems['Share With Team'] = { callback }

        if template.accessLevel is 'group'
          menuItems['Make Private'] = { callback }


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

    (stack?.getIn [ '_revisionStatus', 'status', 'code' ]) or 0


  render: ->

    return null  unless @props.stack.get('machines').length

    className  = 'SidebarStackSection'
    className += ' active'  if @state.selectedTemplateId is @props.stack.get 'baseStackId'

    <SidebarSection
      ref='sidebarSection'
      className={kd.utils.curry className, @props.className}
      title={@props.stack.get 'title'}
      onTitleClick={@bound 'onTitleClick'}
      onMenuIconClick={@bound 'onMenuIconClick'}
      secondaryLink=''
      baseStackId={@props.stack.get 'baseStackId'}
      unreadCount={@getStackUnreadCount()}
      originalTemplateUpdate={@props.stack.getIn ['config', 'needUpdate']}
      unreadCountClickHandler={@bound 'unreadCountClickHandler'}
      >
      {@renderMachines()}
      {@renderStackUpdatedWidget()}
    </SidebarSection>


React.Component.include.call SidebarStackSection, [KDReactorMixin]
