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

          EnvironmentFlux.actions.cloneStackTemplate template
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

          computeController.makeTeamDefault template  unless err
      when 'Share With Team'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'sharing'  if err

          computeController.setStackTemplateAccessLevel template, 'group'
      when 'Make Private'
        computeController.fetchStackTemplate templateId, (err, template) =>
          return @onMenuItemClickError 'cloning'  if err

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
    template = @props.template

    { originId, accessLevel } = template.toJS()  if template

    if @getStackUnreadCount()
      menuItems['Update'] = { callback }

    if @props.stack.getIn ['config', 'remoteDetails', 'originalUrl']
      menuItems['Open on GitLab'] = { callback }

    managedVM = @props.stack.get('title').indexOf('Managed VMs') > -1

    if managedVM
      menuItems['VMs'] = { callback }
    else if @props.stack.get 'disabled'
      # because of disabled stack's baseTemplate came undefined
      # no need to show Edit, Clone, Reinitialize options
      ['VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }
    else
      if isAdmin() or (template and whoami()._id is originId)
        menuItems['Edit'] = { callback }
        menuItems['Clone'] = { callback }  if canCreateStacks()
      else
        menuItems['View Stack'] = { callback }
      ['Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }
      if isAdmin() and not isDefaultTeamStack @props.stack.get 'baseStackId'
        menuItems['Make Team Default'] = { callback }

      if template and whoami()._id is originId and not isDefaultTeamStack @props.stack.get 'baseStackId'
        menuItems['Share With Team'] = { callback }  if accessLevel is 'private'
        menuItems['Make Private'] = { callback }  if accessLevel is 'group'

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
