kd    = require 'kd'
React = require 'kd-react'
Link  = require 'app/components/common/link'


module.exports = class ThreadHeader extends React.Component

  @defaultProps =
    channelThread: null
    messageThread: null
    isSummaryActive: no


  channel: (key) -> @props.channelThread?.getIn ['channel', key]

  message: (key) -> @props.messageThread?.getIn ['message', key]


  renderSummaryToggle: -> null


  renderTitle: ->

    children = []
    if @props.channelThread
      href = "/Channels"
      href += "/#{@channel 'name'}"
      href += "/summary"  unless @props.isSummaryActive
      children.push(
        <span className="ThreadHeader-navLink">
          <Link href={href}>
            {@channel 'name'}
          </Link>
        </span>
      )

    if @props.messageThread
      href = "/Channels"
      href += "/#{@channel 'name'}"
      href += "/summary"  unless @props.isSummaryActive
      href += "/#{@message 'slug'}"
      children.push(
        <span className="ThreadHeader-navLink">
          <Link href={href}>
            {@message 'slug'}
          </Link>
        </span>
      )

    return (
      <div className="ThreadHeader-navContainer">
        {children}
      </div>
    )

  render: ->
    <div className="ThreadHeader">
      {@renderSummaryToggle()}
      {@renderTitle()}
    </div>


