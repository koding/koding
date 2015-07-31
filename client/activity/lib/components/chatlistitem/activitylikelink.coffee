React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'


module.exports = class ActivityLikeLink extends React.Component


  getClassName: ->

    classnames(
      'ChatItem-likeLink': yes
      'is-likedByUser'   : @props.interactions.like.isInteracted
      'is-likedByOthers' : @props.interactions.like.actorsCount
    )


  onClick: ->

    { likeMessage, unlikeMessage } = ActivityFlux.actions.message

    if @props.interactions.like.isInteracted
      unlikeMessage @props.messageId
    else
      likeMessage @props.messageId


  render: ->

    <a className={@getClassName()} onClick={ @bound 'onClick'} ></a>



