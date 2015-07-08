React = require 'kd-react'

helper = require './helper'

module.exports = class ProfilePicture extends React.Component

  @defaultProps =
    width  : 50
    height : 50

  constructor: (props) ->

    super props

    @state = { dpr: global.devicePixelRatio ? 1 }


  getImageProps: ->
    src      : helper.getGravatarUri @props.account, @props.width * @state.dpr
    style    :
      width  : @props.width
      height : @props.height


  render: ->
    <img className="ProfilePicture" {...@getImageProps()} />


