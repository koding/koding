React                 = require 'kd-react'
immutable             = require 'immutable'
ActivityFlux          = require 'activity/flux'
Scroller              = require 'app/components/scroller'
ChannelListItem       = require 'activity/components/channellistitem'

module.exports = class ChannelList extends React.Component

  @defaultProps =
    title       : ''
    threads     : immutable.List()
    className   : ''


  componentWillUpdate: ->

    return  unless @refs?.scrollContainer

    { @scrollTop, offsetHeight, @scrollHeight } = React.findDOMNode @refs.scrollContainer
    @shouldScrollToBottom = @scrollTop + offsetHeight is @scrollHeight


  componentDidUpdate: ->

    return  unless @refs?.scrollContainer

    element = React.findDOMNode @refs.scrollContainer

    if @shouldScrollToBottom
      element.scrollTop = element.scrollHeight
    else
      element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)


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


  renderChildren: ->

    { threads } = @props

    threads.map (thread, i) ->
      itemProps =
        key     : thread.get 'channelId'
        channel : thread.get 'channel'

      <ChannelListItem {...itemProps} />


  renderChannelList: ->
    <div className='ChannelList'>
      <Scroller
        onThresholdReached={@bound 'onThresholdReached'}
        ref="scrollContainer">
        {@renderChildren().toList()}
      </Scroller>
    </div>


  render: ->
    <div className='ChannelListWrapper'>
      {@renderHeader()}
      {@renderChannelList()}
    </div>

