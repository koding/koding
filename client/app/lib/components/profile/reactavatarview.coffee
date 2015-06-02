kd                   = require 'kd'
React                = require 'app/react'
ReactView            = require 'app/react/reactview'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
Avatar               = require 'app/components/profile/avatar'


module.exports = class ReactAvatarView extends ReactView

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry 'avatarview', options.cssClass

    options.size        or=
      width               : 50
      height              : 50
    options.size.width   ?= 50
    options.size.height  ?= options.size.width

    super options, data


  getContainerProps: ->

    props = {}

    if data = @getData()
      props.account = data
    else
      props.origin = @options.origin

    return props


  getAvatarProps: ->
    width  : @options.size.width
    height : @options.size.height


  renderReact: ->
    <ProfileLinkContainer {...@getContainerProps()}>
      <Avatar {...@getAvatarProps()} />
    </ProfileLinkContainer>



