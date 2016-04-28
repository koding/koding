kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
KDReactorMixin            = require 'app/flux/base/reactormixin'
EnvironmentFlux           = require 'app/flux/environment'
StackUpdatedWidget        = require './stackupdatedwidget'
getBoundingClientReact    = require 'app/util/getBoundingClientReact'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'


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


  renderStackUpdatedWidget: ->

    { coordinates } = @state

    return null  unless @getStackUnreadCount()
    return null  if not coordinates.left and coordinates.top

    <StackUpdatedWidget
      coordinates={coordinates}
      stack={@props.stack} />


  unreadCountClickHandler: ->

    { router } = kd.singletons

    router.handleRoute '/Stacks/My-Stacks'


  getStackUnreadCount: ->

    @props.stack.getIn [ '_revisionStatus', 'status', 'code' ]


  render: ->

    return null  unless @props.stack.get('machines').length

    className  = 'SidebarStackSection'
    className += ' active'  if @state.activeStack is @props.stack.get '_id'

    titleLink = "/Stack-Editor/#{@props.stack.get 'baseStackId'}"

    <SidebarSection
      ref='sidebarSection'
      className={kd.utils.curry className, @props.className}
      title={@props.stack.get 'title'}
      titleLink={titleLink}
      secondaryLink=''
      unreadCount={@getStackUnreadCount()}
      unreadCountClickHandler={@unreadCountClickHandler}
      >
      {@renderMachines()}
      {@renderStackUpdatedWidget()}
    </SidebarSection>


React.Component.include.call SidebarStackSection, [KDReactorMixin]
