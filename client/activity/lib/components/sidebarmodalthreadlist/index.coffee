kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
Scroller       = require 'app/components/scroller'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
classnames     = require 'classnames'

module.exports = class SidebarModalThreadList extends React.Component

  @include [ScrollerMixin]

  @defaultProps =
    threads           : immutable.List()
    className         : ''
    onItemClick       : kd.noop


  onThresholdReached: -> @props.onThresholdReached? { skip: @props.threads.size }


  renderChildren: ->

    { itemComponent: Component, onItemClick, threads } = @props

    threads.toList().map (thread, i) ->
      itemProps =
        thread      : thread
        key         : thread.get 'channelId'
        onItemClick : onItemClick
      <Component {...itemProps} />


  renderNoResultText: ->

    { noResultText } = @props
    return  if @props.threads.size > 0    

    <div>
      {noResultText}
    </div>


  render: ->

    <div className={"ChannelList #{@props.className}"}>
      <Scroller
        onThresholdReached={@bound 'onThresholdReached'}
        ref="scrollContainer">
        {@renderChildren()}
        {@renderNoResultText()}
      </Scroller>
    </div>

