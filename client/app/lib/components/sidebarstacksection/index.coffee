kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarList               = require 'app/components/sidebarlist'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'


module.exports = class SidebarStackSection extends React.Component

  @defaultProps   =
    selectedId    : null
    stack         : immutable.Map()


  componentDidMount: ->

    @props.onStackRendered()


  renderMachines: ->

    @props.stack.get('machines').map (machine) =>
      <SidebarMachinesListItem
        key={machine.get '_id'}
        machine={machine}
        active={machine.get('_id') is @props.selectedId}
        />


  render: ->

    <SidebarSection
      className={kd.utils.curry 'SidebarStackSection', @props.className}
      secondaryLink='/Settings/Stacks'
      title={@props.stack.get 'title'}
      titleLink='/Stacks'
      unreadCount={@props.stack.getIn [ '_revisionStatus', 'status', 'code' ]}
      >
      {@renderMachines()}
    </SidebarSection>


