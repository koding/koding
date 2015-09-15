React                   = require 'kd-react'
immutable               = require 'immutable'
SidebarList             = require 'app/components/sidebarlist'
SidebarSection          = require 'app/components/sidebarsection'
SidebarMessagesListItem = require 'app/components/sidebarmessageslistitem'
Modal                   = require 'app/components/modal'
SidebarModalList        = require 'activity/components/sidebarmodallist'
PrivateChannelListItem  = require 'activity/components/privatechannellistitem'

module.exports = class SidebarMessagesSection extends React.Component

  @defaultProps =
    threads    : immutable.Map()
    selectedId : null


  constructor: (props) ->

    super

    @state = { isModalOpen: no }


  onClose: ->

    @setState isModalOpen: no


  showPrivateChannelsModal: ->

    @setState isModalOpen: yes


  renderPrivateChannelsModal: ->

    <Modal
      className='ChannelList-Modal'
      isOpen={@state.isModalOpen}
      closeOnOutsideClick=no
      onClose={@bound 'onClose'}>
      <SidebarModalList
        title='Other Messages:'
        threads={@props.threads}
        itemComponent={PrivateChannelListItem}/>
    </Modal>


  renderMoreLink: ->

    { threads, previewCount } = @props

    if threads.size > previewCount
      <a className='SidebarList-showMore' onClick={@bound 'showPrivateChannelsModal'}>More ...</a>


  render: ->

    <div>
      <SidebarSection
        title="Messages"
        onHeaderClick={@bound 'showPrivateChannelsModal'}
        className="SidebarMessagesSection">
        <SidebarList
          previewCount={@props.previewCount}
          itemComponent={SidebarMessagesListItem}
          threads={@props.threads}
          selectedId={@props.selectedId} />
          {@renderMoreLink()}
      </SidebarSection>
      {@renderPrivateChannelsModal()}
    </div>
