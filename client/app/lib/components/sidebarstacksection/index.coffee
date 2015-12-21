kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'

module.exports = class SidebarStackSection extends React.Component

  @defaultProps   =
    selectedId    : null
    stack         : immutable.Map()


  renderMachines: ->

    config = @props.stack.get 'config'

    @props.stack.get('machines').map (machine) =>
      visible = config?.getIn [ 'sidebar', machine.get('uid'), 'visibility' ]
      <SidebarMachinesListItem
        key={machine.get '_id'}
        machine={machine}
        showInSidebar={visible}
        />


  render: ->

    return null  unless @props.stack.get('machines').length

    <SidebarSection
      className={kd.utils.curry 'SidebarStackSection', @props.className}
      title={@props.stack.get 'title'}
      titleLink='/Stacks'
      secondaryLink='/Stacks'
      unreadCount={@props.stack.getIn [ '_revisionStatus', 'status', 'code' ]}
      >
      {@renderMachines()}
    </SidebarSection>


