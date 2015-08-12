React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Link         = require 'app/components/common/link'


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
    then unlikeMessage @props.messageId
    else likeMessage @props.messageId


  render: ->

    <Link className={@getClassName()} onClick={@bound 'onClick'} ></Link>



