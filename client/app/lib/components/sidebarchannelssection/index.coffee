React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
Modal                   = require 'app/components/modal'
ChannelList             = require 'activity/components/channellist'
SidebarChannelsListItem = require 'app/components/sidebarchannelslistitem'

module.exports = class SidebarChannelsSection extends React.Component

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

    { threads, previewCount } = @props

    if threads.size > previewCount
      <a className='SidebarList-showMore' onClick={@bound 'showFollowedPublicChannelsModal'}>More ...</a>


  render: ->

    <div>
      <SidebarSection title="Channels" onHeaderClick={@bound 'showFollowedPublicChannelsModal'} className="SidebarChannelsSection">
        <SidebarList
          previewCount={@props.previewCount}
          itemComponent={SidebarChannelsListItem}
          threads={@props.threads}
          selectedId={@props.selectedId} />
          {@renderMoreLink()}
      </SidebarSection>
      {@renderFollowedChannelsModal()}
    </div>

