kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
KDReactorMixin            = require 'app/flux/base/reactormixin'
EnvironmentFlux           = require 'app/flux/environment'
StackUpdatedWidget        = require './stackupdatedwidget'
getBoundingClientReact    = require 'app/util/getBoundingClientReact'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'
{ findDOMNode } = require 'react-dom'

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


  getDataBindings: ->
    activeStack : EnvironmentFlux.getters.activeStack


  componentWillReceiveProps: -> @setCoordinates()


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

    { router } = kd.singletons
    { stack } = @props

    { title } = item.getData()
    MENU.destroy()

    switch title
      when 'Update' then EnvironmentFlux.actions.reinitStackFromWidget stack
      when 'Edit' then router.handleRoute "/Stack-Editor/#{stack.get 'baseStackId'}"
      when 'Reinitialize' then EnvironmentFlux.actions.reinitStackFromWidget stack
      when 'Destroy VMs' then EnvironmentFlux.actions.deleteStack { stack }
      when 'VMs' then router.handleRoute "/Home/Stacks/virtual-machines"


  onTitleClick: (event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if MENU

    callback = @bound 'onMenuItemClick'

    menuItems = {}

    if @getStackUnreadCount()
      menuItems['Update'] = { callback }

    managedVM = if @props.stack.get('title').indexOf('Managed VMs') > -1
    then yes else no

    if managedVM
    then menuItems['VMs'] = { callback }
    else
      ['Edit', 'Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) =>
        menuItems[name] = { callback }

    { top } = findDOMNode(this).getBoundingClientRect()

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: top + 31 }

    MENU = new kd.ContextMenu menuOptions, menuItems

    MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> MENU = null


  renderStackUpdatedWidget: ->

    { coordinates } = @state

    return null  unless @getStackUnreadCount()
    return null  if not coordinates.left and coordinates.top

    <StackUpdatedWidget coordinates={coordinates} stack={@props.stack} />


  unreadCountClickHandler: ->

    { router } = kd.singletons

    router.handleRoute '/Stacks/My-Stacks'


  getStackUnreadCount: ->

    @props.stack.getIn [ '_revisionStatus', 'status', 'code' ]


  render: ->

    return null  unless @props.stack.get('machines').length

    className  = 'SidebarStackSection'
    className += ' active'  if @state.activeStack is @props.stack.get '_id'


    <SidebarSection
      ref='sidebarSection'
      className={kd.utils.curry className, @props.className}
      title={@props.stack.get 'title'}
      onTitleClick={@bound 'onTitleClick'}
      secondaryLink=''
      unreadCount={@getStackUnreadCount()}
      unreadCountClickHandler={@unreadCountClickHandler}
      >
      {@renderMachines()}
      {@renderStackUpdatedWidget()}
    </SidebarSection>


React.Component.include.call SidebarStackSection, [KDReactorMixin]
