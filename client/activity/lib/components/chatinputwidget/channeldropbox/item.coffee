kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
DropboxItem = require 'activity/components/dropboxitem'


module.exports = class ChannelDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item } = @props
    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated ChannelDropboxItem">
      <span className="ChannelDropboxItem-hash"># </span>
      {item.get 'name'}
    </DropboxItem>
