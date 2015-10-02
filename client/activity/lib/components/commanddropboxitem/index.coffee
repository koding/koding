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
    <DropboxItem {...@props} className='DropboxItem-singleLine DropboxItem-separated CommandDropboxItem'>
      <span className='CommandDropboxItem-name'>{item.get 'name'}</span>
      <span className='CommandDropboxItem-params'>{item.get 'extraInfo'}</span>
      <span className='CommandDropboxItem-description'>{item.get 'description'}</span>
    </DropboxItem>

