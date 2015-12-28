kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
StackUpdatedWidget        = require './stackupdatedwidget'
getBoundingClientReact    = require 'app/util/getBoundingClientReact'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'


module.exports = class SidebarStackSection extends React.Component

  @defaultProps =
    selectedId                  : null
    stack                       : immutable.Map()


  constructor: ->

    super

    @state        =
      coordinates :
        left      : 0
        top       : 0


  componentWillReceiveProps: -> @setCoordinates()


  componentDidMount: -> @setCoordinates()


  setCoordinates: ->

    return  unless @refs.sidebarSection

    coordinates = getBoundingClientReact @refs.sidebarSection
    @setState { coordinates: coordinates }


  renderMachines: ->

    config = @props.stack.get 'config'

    @props.stack.get('machines').map (machine) =>
      visible = config?.getIn [ 'sidebar', machine.get('uid'), 'visibility' ]
      <SidebarMachinesListItem
        key={machine.get '_id'}
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

    router.handleRoute '/Stacks'


  getStackUnreadCount: ->

    @props.stack.getIn [ '_revisionStatus', 'status', 'code' ]


  render: ->

    return null  unless @props.stack.get('machines').length

    <SidebarSection
      ref='sidebarSection'
      className={kd.utils.curry 'SidebarStackSection', @props.className}
      title={@props.stack.get 'title'}
      titleLink='/Stacks'
      secondaryLink='/Stacks'
      unreadCount={@getStackUnreadCount()}
      unreadCountClickHandler={@unreadCountClickHandler}
      >
      {@renderMachines()}
      {@renderStackUpdatedWidget()}
    </SidebarSection>
