kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
Scroller       = require 'app/components/scroller'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
classnames     = require 'classnames'

PublicChannelListItem = require 'activity/components/publicchannellistitem'

module.exports = class SidebarModalThreadList extends React.Component

  @include [ScrollerMixin]

  @defaultProps =
    threads           : immutable.List()
    className         : ''
    onItemClick       : kd.noop


  onThresholdReached: -> @props.onThresholdReached? { skip: @props.threads.size }


  renderChildren: ->

    { onItemClick, threads } = @props

    threads.toList().map (thread, i) ->
      itemProps =
        thread      : thread
        key         : thread.get 'channelId'
        onItemClick : onItemClick
      <PublicChannelListItem {...itemProps} />


  renderNoResultText: ->

    { noResultText } = @props
    return  if @props.threads.size > 0    

    <div>
      {noResultText}
    </div>


  render: ->

    <div className={"SidebarModalThreadList #{@props.className}"}>
      <Scroller
        onThresholdReached={@bound 'onThresholdReached'}
        ref="scrollContainer">
        {@renderChildren()}
        {@renderNoResultText()}
      </Scroller>
    </div>

