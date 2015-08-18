React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
SidebarMessagesListItem = require 'app/components/sidebarmessageslistitem'


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
