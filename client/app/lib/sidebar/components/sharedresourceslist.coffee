React = require 'app/react'

List = require 'app/components/list'
Link = require 'app/components/common/link'

SidebarMachineItem = require './machineitemcontainer'

module.exports = class SharedResourcesList extends React.Component

  getMachines: (index) ->

    { resources: { permanent = [], collaboration = [] } } = @props

    machines = permanent.concat(collaboration)

    return if index? then machines[index] else machines


  getSectionCount: -> 1


  getRowCount: -> @getMachines().length


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    machine = @getMachines rowIndex

    <SidebarMachineItem machineId={machine.getId()} />


  render: ->
    { resources: { permanent, collaboration } } = @props

    machines = permanent.concat collaboration

    <div className='SidebarSection SidebarSharedMachinesSection'>
      <SectionHeader />
      <List
        rowClassName='SidebarSection-body'
        numberOfSections={@bound 'getSectionCount'}
        numberOfRowsInSection={@bound 'getRowCount'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
      />
    </div>

SectionHeader = ({ children }) ->

  <header className="SidebarSection-header">
    <h4 className='SidebarSection-headerTitle'>
      <Link>Shared VMs</Link>
    </h4>
  </header>
