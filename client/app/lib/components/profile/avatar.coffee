kd    = require 'kd'
React = require 'app/react'

ProfilePicture = require './profilepicture'

module.exports = class Avatar extends React.Component

  @defaultProps =
    onClick : kd.noop
    width   : 50
    height  : 50

  getPictureProps: ->
    width   : @props.width
    height  : @props.height
    account : @props.account

  render: ->
    <ProfilePicture {...@getPictureProps()} />
