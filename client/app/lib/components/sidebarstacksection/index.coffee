kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarList               = require 'app/components/sidebarlist'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMachinesListItem   = require 'app/components/sidebarmachineslistitem'


module.exports = class SidebarStackSection extends React.Component

  @defaultProps =
    sectionTitle  : 'Default Stack'
    titleLink     : '#'
    secondaryLink : '#'
    selectedId    : null
    machines      : immutable.List()
    stack         : immutable.Map()
    previewCount  : 0
    unreadCount   : 1

  renderMachines: ->

    @props.machines
      .sortBy (machine) -> machine.get '_id'
      .toList()
      .map (machine) =>
        <SidebarMachinesListItem
          key={machine.get '_id'}
          machine={machine}
          active={machine.get('_id') is @props.selectedId}
          />


  render: ->

    <SidebarSection
      unreadCount={@props.unreadCount}
      title={@props.sectionTitle}
      titleLink={@props.titleLink}
      secondaryLink={@props.secondaryLink}
      className={kd.utils.curry 'SidebarStackSection', @props.className}>
      {@renderMachines()}
    </SidebarSection>


