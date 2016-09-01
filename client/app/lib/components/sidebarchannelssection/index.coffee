React                    = require 'kd-react'
immutable                = require 'immutable'
SidebarList              = require 'app/components/sidebarlist'
SidebarSection           = require 'app/components/sidebarsection'
SidebarChannelsListItem  = require 'app/components/sidebarchannelslistitem'

require './styl/sidebarchannelssection.styl'


module.exports = class SidebarChannelsSection extends React.Component

  @defaultProps =
    selectedId   : null
    threads      : immutable.Map()


  render: ->

    <SidebarSection
      title="Channels"
      titleLink="/AllChannels"
      secondaryLink="/NewChannel"
      className="SidebarChannelsSection">
      <SidebarList
        itemComponent={SidebarChannelsListItem}
        componentProp='SidebarChannelsListItem'
        threads={@props.threads}
        selectedId={@props.selectedId} />
    </SidebarSection>


