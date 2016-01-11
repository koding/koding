React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarList               = require 'app/components/sidebarlist'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMessagesListItem   = require 'app/components/sidebarmessageslistitem'
Link                      = require 'app/components/common/link'


module.exports = class SidebarMessagesSection extends React.Component

  @defaultProps =
    selectedId   : null
    threads      : immutable.Map()
    previewCount : 0


  renderMoreLink: ->

    { threads, previewCount } = @props

    if threads.size > previewCount
      <Link className='SidebarList-showMore' href="/Messages">More ...</Link>


  render: ->

    <div>
      <SidebarSection
        title="Messages"
        titleLink="/AllMessages"
        secondaryLink="/NewMessage"
        className="SidebarMessagesSection">
        <SidebarList
          previewCount={@props.previewCount}
          itemComponent={SidebarMessagesListItem}
          componentProp='SidebarMessagesListItem'
          threads={@props.threads}
          selectedId={@props.selectedId} />
        {@renderMoreLink()}
      </SidebarSection>
    </div>
