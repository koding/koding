kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
DropboxItem = require 'activity/components/dropboxitem'


module.exports = class CommandDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item } = @props
    <DropboxItem {...@props} className="CommandDropboxItem">
      {item.get 'name'}
    </DropboxItem>

