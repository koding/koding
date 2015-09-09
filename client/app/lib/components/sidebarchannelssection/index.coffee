kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
Modal                   = require 'app/components/modal'
ChannelList             = require 'activity/components/channellist'
SidebarChannelsListItem = require 'app/components/sidebarchannelslistitem'

module.exports = class SidebarChannelsSection extends React.Component

  PREVIEW_COUNT = 10

  @defaultProps =
    threads    : immutable.Map()
    selectedId : null

  constructor: (props) ->

    super

    @state = { browseChannels: no }


  onClose: ->

    @setState browseChannels: no


  showFollowedChannelsModal: ->

    @setState browseChannels: yes


  renderFollowedChannelsModal: ->

    title = 'Other Channels you are following:'
    <Modal className='ChannelList-Modal' isOpen={@state.browseChannels} onClose={@bound 'onClose'}>
      <ChannelList threads={@props.threads} title={title} />
    </Modal>


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

