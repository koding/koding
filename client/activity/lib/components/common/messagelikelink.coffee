React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Link         = require 'app/components/common/link'


module.exports = class MessageLikeLink extends React.Component

  getClassName: ->

    { message } = @props

    classnames(
      'MessageLikeLink'  : yes
      'is-likedByUser'   : message.getIn ['interactions', 'like', 'isInteracted']
      'is-likedByOthers' : message.getIn ['interactions', 'like', 'actorsCount']
    )


  onClick: ->

    { likeMessage, unlikeMessage } = ActivityFlux.actions.message

    messageId = @props.message.get 'id'
    isInteracted = @props.message.getIn ['interactions', 'like', 'isInteracted']

    if isInteracted
    then unlikeMessage messageId
    else likeMessage messageId


  render: ->
    <Link
      className={@getClassName()}
      onClick={@bound 'onClick'} />




