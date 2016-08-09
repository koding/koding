kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
KDReactorMixin            = require 'app/flux/base/reactormixin'
EnvironmentFlux           = require 'app/flux/environment'
StackUpdatedWidget        = require './stackupdatedwidget'
getBoundingClientReact    = require 'app/util/getBoundingClientReact'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'
isAdmin = require 'app/util/isAdmin'
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

    { appManager, router } = kd.singletons
    { stack } = @props
    { reinitStackFromWidget, deleteStack } = EnvironmentFlux.actions

    { title } = item.getData()
    MENU.destroy()

    templateId = stack.get 'baseStackId'

    switch title
      when 'Edit' then router.handleRoute "/Stack-Editor/#{templateId}"
      when 'Reinitialize', 'Update'
        reinitStackFromWidget(stack).then ->
          # invalidate editor cache
          appManager.tell 'Stackeditor', 'reloadEditor', templateId
      when 'Destroy VMs' then deleteStack { stack }
      when 'VMs' then router.handleRoute "/Home/Stacks/virtual-machines"


  onTitleClick: (event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if MENU

    callback = @bound 'onMenuItemClick'

    menuItems = {}

    if @getStackUnreadCount()
      menuItems['Update'] = { callback }

    managedVM = @props.stack.get('title').indexOf('Managed VMs') > -1

    if managedVM
      menuItems['VMs'] = { callback }
    else
      menuItems['Edit'] = { callback }  if isAdmin()
      ['Reinitialize', 'VMs', 'Destroy VMs'].forEach (name) ->
        menuItems[name] = { callback }

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

    <StackUpdatedWidget coordinates={coordinates} stack={@props.stack} show={showWidget} />


  unreadCountClickHandler: ->

    @setState { showWidget: yes }


  getStackUnreadCount: ->

    @props.stack.getIn [ '_revisionStatus', 'status', 'code' ]


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


React.Component.include.call SidebarStackSection, [KDReactorMixin]
