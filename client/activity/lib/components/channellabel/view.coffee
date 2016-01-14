kd                 = require 'kd'
React              = require 'kd-react'
immutable          = require 'immutable'
prepareThreadTitle = require 'activity/util/prepareThreadTitle'

module.exports = class ChannelLabelView extends React.Component

  @propTypes =
    className : React.PropTypes.string
    channel   : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    className : ''
    channel   : immutable.Map()


  render: ->

    isPrivate = @props.channel.get('typeConstant') is 'privatemessage'

    child = if isPrivate
    then prepareThreadTitle @props.channel
    else "##{@props.channel.get 'name'}"

    className = kd.utils.curry "ChannelLabel", @props.className

    <span className={className}>{child}</span>

