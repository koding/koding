React                     = require 'kd-react'
immutable                 = require 'immutable'
SidebarList               = require 'app/components/sidebarlist'
SidebarSection            = require 'app/components/sidebarsection'
SidebarMessagesListItem   = require 'app/components/sidebarmessageslistitem'


module.exports = class SidebarMessagesSection extends React.Component

  @defaultProps =
    selectedId   : null
    threads      : immutable.Map()


  render: ->

    <SidebarSection
      title="Messages"
      titleLink="/AllMessages"
      secondaryLink="/NewMessage"
      className="SidebarMessagesSection">
      <SidebarList
        itemComponent={SidebarMessagesListItem}
        componentProp='SidebarMessagesListItem'
        threads={@props.threads}
        selectedId={@props.selectedId} />
    </SidebarSection>


