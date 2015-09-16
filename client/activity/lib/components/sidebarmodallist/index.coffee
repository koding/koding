kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
Scroller       = require 'app/components/scroller'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
classnames     = require 'classnames'

module.exports = class SidebarModalList extends React.Component

  @include [ScrollerMixin]

  @defaultProps =
    title             : ''
    threads           : immutable.List()
    className         : ''
    searchProp        : 'name'
    onThresholdAction : ''

  constructor: (props) ->

    super

    @state = { threads: @props.sidebarModalChannels.followed, emptySearchText: no, value: '', isSearching: no }


  onThresholdReached: ->

    { channel } = ActivityFlux.actions

    channel.loadFollowedPublicChannels skip: @props.threads.size


  onChange: ->

    console.log 'onchange'


  onKeyDown: ->

    console.log 'onKeyDown'


  renderHeader: ->

    <div>
      <div className='ChannelList-title'>{@props.title}</div>
      <div>
        <input
          className   = 'ChannelList-searchInput'
          placeholder = 'Search'
          onChange    = { @bound 'onChange' }
          onKeyDown   = { @bound 'onKeyDown' }
          ref         = 'ChannelSearchInput'
        />
      </div>
    </div>


  getNoResultClassNames: -> classnames
    'ChannelList-emptySearch': yes
    'hidden' : not @state.emptySearchText


  renderChildren: ->

    { itemComponent: Component, threads } = @props

    @state.threads.toList().map (thread, i) ->
      itemProps =
        key     : thread.get 'channelId'
        channel : thread.get 'channel'
      <Component {...itemProps} />


  renderNoResultText: ->

    <div className={@getNoResultClassNames()}>Sorry, your search did not have any results</div>


  renderChannelList: ->

    <div className='ChannelList'>
      <Scroller
        onThresholdReached={@bound 'onThresholdReached'}
        ref="scrollContainer">
        {@renderChildren()}
        {@renderNoResultText()}
      </Scroller>
    </div>


  render: ->

    <div className='ChannelListWrapper'>
      {@renderHeader()}
      {@renderChannelList()}
    </div>

