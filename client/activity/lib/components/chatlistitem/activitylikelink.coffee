React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Tooltip      = require 'app/components/tooltip'
ProfileText  = require 'app/components/profile/profiletext'


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


  renderTooltipItems: (participant) ->

    { actorsPreview } = @props.interactions.like

    for id, account of actorsPreview when account

      <ProfileText key={id} account={account} />


  renderTooltip: ->

    { actorsCount } = @props.interactions.like

    return null  unless actorsCount

    <Tooltip>
      {@renderTooltipItems()}
    </Tooltip>


  render: ->

    <a className={@getClassName()} onClick={ @bound 'onClick' } >
      {@renderTooltip()}
    </a>



