React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
SidebarMessagesListItem = require 'app/components/sidebarmessageslistitem'


module.exports = class SidebarMessagesSection extends React.Component

  @defaultProps =
    threads    : immutable.Map()
    selectedId : null


  render: ->
    <SidebarSection title="Messages" className="SidebarMessagesSection">
      <SidebarList
        itemComponent={SidebarMessagesListItem}
  constructor: (props) ->

    super

    @state = { browsePrivateChannels: no }


  onClose: ->

    @setState browsePrivateChannels: no


  showPrivateChannelsModal: ->

    @setState browsePrivateChannels: yes


  renderPrivateChannelsModal: ->

    <Modal
      className='ChannelList-Modal'
      isOpen={@state.browsePrivateChannels}
      closeOnOutsideClick=no
      onClose={@bound 'onClose'}>
      <ChannelList
        title='Other Messages:'
        threads={@props.threads}
        itemComponent={PrivateChannelListItem}/>
    </Modal>

