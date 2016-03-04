kd          = require 'kd'
React       = require 'kd-react'
DropboxItem = require 'activity/components/dropboxitem'


module.exports = class ErrorDropboxItem extends React.Component

  render: ->

    <DropboxItem className='DropboxItem-singleLine ErrorDropboxItem'>
      { @props.children }
    </DropboxItem>
