React = require 'app/react'

helper = require './helper'

require './styl/profile.styl'

module.exports = class ProfilePicture extends React.Component

  @defaultProps =
    width  : 50
    height : 50

  constructor: (props) ->

    super props

    @state = { dpr: global.devicePixelRatio ? 1 }


  getImageProps: ->

    { account, width, height } = @props
    { dpr } = @state

    avatarUri = helper.getAvatarUri account, width, height, dpr

    src      : avatarUri
    style    :
      width  : @props.width
      height : @props.height


  render: ->

    { role } = @props

    <span>
      <img className="ProfilePicture" {...@getImageProps()} />
      <div className={"badge #{role}"} title={role}></div>
    </span>
