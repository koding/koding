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

  renderMoreLink: ->

    { threads } = @props

    if threads.size > PREVIEW_COUNT
      <a className='SidebarList-showMore' onClick={@bound 'showFollowedChannelsModal'}>More ...</a>


  render: ->
    <div>
      <SidebarSection title="Channels" onHeaderClick={@bound 'showFollowedChannelsModal'} className="SidebarChannelsSection">
        <SidebarList
          previewCount={PREVIEW_COUNT}
          itemComponent={SidebarChannelsListItem}
          threads={@props.threads}
          selectedId={@props.selectedId} />
          {@renderMoreLink()}
      </SidebarSection>
      {@renderFollowedChannelsModal()}
    </div>

