React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
Modal                   = require 'app/components/modal'
SidebarModalList        = require 'activity/components/sidebarmodallist'
PublicChannelListItem   = require 'activity/components/channellistitem'
SidebarChannelsListItem = require 'app/components/sidebarchannelslistitem'

module.exports = class SidebarChannelsSection extends React.Component

  @defaultProps =
    selectedId : null
    threads    : immutable.Map()

  constructor: (props) ->

    super

    @state = { isModalOpen: no }


  onClose: ->

    @setState isModalOpen: no


  showFollowedPublicChannelsModal: ->

    @setState isModalOpen: yes


  renderFollowedChannelsModal: ->

    title = 'Other Channels you are following:'
    <Modal className='ChannelList-Modal' isOpen={@state.isModalOpen} onClose={@bound 'onClose'}>
      <SidebarModalList
        title={title}
        searchProp='name'
        threads={@props.threads}
        onThresholdAction='loadFollowedPublicChannels'
        itemComponent={PublicChannelListItem}/>
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

