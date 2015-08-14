kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
SidebarChannelsListItem = require 'app/components/sidebarchannelslistitem'


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


