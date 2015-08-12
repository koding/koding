React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'activity/components/sidebarlist'
SidebarSection          = require 'activity/components/sidebarsection'
SidebarMessagesListItem = require 'activity/components/sidebarmessageslistitem'


module.exports = class SidebarMessagesSection extends React.Component

  @defaultProps =
    threads    : immutable.Map()
    selectedId : null


  render: ->
    <SidebarSection title="Messages" className="SidebarMessagesSection">
      <SidebarList
        itemComponent={SidebarMessagesListItem}
        threads={@props.threads}
        selectedId={@props.selectedId} />
    </SidebarSection>
