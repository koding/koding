kd                  = require 'kd'
React               = require 'kd-react'
Modal               = require 'app/components/modal'
Header              = require './header'
TabView             = require './tabview'
classnames          = require 'classnames'
SidebarModalThreads = require 'activity/components/sidebarmodalthreads'

module.exports = class BrowsePublicChannelsModalView extends React.Component

  @defaultProps =
    isOpen              : yes
    className           : ''
    query               : ''
    onClose             : kd.noop
    onTabChange         : kd.noop
    isSearchActive      : no
    onItemClick         : kd.noop
    onThresholdReached  : kd.noop
    onSearchInputChange : kd.noop

  getClassNames: -> classnames
    'ChannelListWrapper' : yes
    'active-search'      : @props.isSearchActive


  renderHeader: ->

    <Header query={@props.query} onSearchInputChange={@props.onSearchInputChange}/>


  renderTabs: ->

    className = classnames { 'hidden' : @props.isSearchActive }

    <TabView activeTab={@props.activeTab} onChange={@props.onTabChange} className={className}/>


  renderList: ->

    noResutText  = 'Sorry, your search did not have any results'  if @props.isSearchActive

    <SidebarModalThreads
      threads            = { @props.channels }
      noResultText       = { noResutText }
      onThresholdReached = { @props.onThresholdReached }
      onItemClick        = { @props.onItemClick }
    />


  render: ->

    <Modal className='ChannelList-Modal PublicChannelListModal' isOpen={@props.isOpen} onClose={@props.onClose}>
      <div className={@getClassNames()}>
        { @renderHeader() }
        { @renderTabs() }
        { @renderList() }
      </div>
    </Modal>