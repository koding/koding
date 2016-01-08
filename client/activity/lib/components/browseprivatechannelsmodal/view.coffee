kd                     = require 'kd'
React                  = require 'kd-react'
Modal                  = require 'app/components/modal'
immutable              = require 'immutable'
SidebarModalList       = require 'activity/components/sidebarmodallist'
PrivateChannelListItem = require 'activity/components/privatechannellistitem'

module.exports = class BrowsePrivateChannelsModalView extends React.Component

  @defaultProps =
    isOpen      : yes
    threads     : immutable.Map()
    onClose     : kd.noop
    onItemClick : kd.noop

  render: ->

    title = 'Other Messages:'
    <Modal className='ChannelList-Modal PrivateChannelListModal' isOpen={@props.isOpen} onClose={@props.onClose}>
      <SidebarModalList
        ref='SidebarModalList'
        title={title}
        searchProp='name'
        threads={@props.threads}
        onThresholdAction='loadFollowedPrivateChannels'
        onItemClick={@props.onItemClick}
        itemComponent={PrivateChannelListItem}/>
    </Modal>

