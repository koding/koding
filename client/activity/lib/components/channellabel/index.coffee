kd                 = require 'kd'
React              = require 'kd-react'
prepareThreadTitle = require 'activity/util/prepareThreadTitle'


module.exports = class ChannelLabel extends React.Component

  channel: (keyPath...) -> @props.thread.getIn ['channel'].concat keyPath

  render: ->
    isPrivate = @channel('typeConstant') is 'privatemessage'

    child = if isPrivate
    then prepareThreadTitle @props.thread
    else "##{@channel 'name'}"

    className = kd.utils.curry "ChannelLabel", @props.className

    <span className={className}>{child}</span>
