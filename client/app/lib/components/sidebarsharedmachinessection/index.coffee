kd                      = require 'kd'
React                   = require 'kd-react'
SidebarSection          = require 'app/components/sidebarsection'
SidebarMachinesListItem = require 'app/components/sidebarmachineslistitem'


module.exports = class SidebarSharedMachinesSection extends React.Component

  renderMachines: ->

    machines = @props.machines.shared.concat @props.machines.collaboration

    machines.map (machine) =>

      <SidebarMachinesListItem
        key={machine.get '_id'}
        machine={machine}
        activeLeavingSharedMachineId={@props.activeLeavingSharedMachineId} />


  render: ->

    <SidebarSection
      className={kd.utils.curry 'SidebarSharedMachinesSection', @props.className}
      title={@props.sectionTitle}>
      {@renderMachines()}
    </SidebarSection>
