kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarList               = require 'app/components/sidebarlist'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'
ReactDOM                  = require 'react-dom'


module.exports = class SidebarSharedMachinesSection extends React.Component

  renderMachines: ->

    machines = @props.machines.shared.concat @props.machines.collaboration

    machines.map (machine) =>

      <SidebarMachinesListItem
        key={machine.get '_id'}
        machine={machine}
        active={machine.get('_id') is @props.selectedId}
        renderedStacksCount={@props.renderedStacksCount}
        activeLeavingSharedMachineId={@props.activeLeavingSharedMachineId} />


  render: ->

    <SidebarSection
      className={kd.utils.curry 'SidebarSharedMachinesSection', @props.className}
      title={@props.sectionTitle}>
      {@renderMachines()}
    </SidebarSection>
