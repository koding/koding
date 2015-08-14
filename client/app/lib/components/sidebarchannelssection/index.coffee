kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'activity/components/sidebarlist'
SidebarSection          = require 'activity/components/sidebarsection'
SidebarChannelsListItem = require 'activity/components/sidebarchannelslistitem'


module.exports = class SidebarChannelsSection extends React.Component

  @defaultProps =
    threads    : immutable.Map()
    selectedId : null

  render: ->
    <SidebarSection title="Channels" className="SidebarChannelsSection">
      <SidebarList
        itemComponent={SidebarChannelsListItem}
        threads={@props.threads}
        selectedId={@props.selectedId} />
    </SidebarSection>


