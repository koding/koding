kd = require 'kd'
Link  = require 'app/components/common/link'
React = require 'react'
SidebarMachine = require 'lab/SidebarMachine'


module.exports = class SidebarManagedVMs extends React.Component

  @propTypes =
    machines: React.PropTypes.array

  @defaultProps =
    machines: []

  renderSharedVMs: ->

    @props.machines.map (machine) ->
      <SidebarMachine key={machine._id} machine={machine} />

  render: ->

    <div className='SidebarManagedVMs SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Home/Stacks/virtual-machines'>
        SHARED VMS
      </Link>
      {@renderSharedVMs()}
    </div>
