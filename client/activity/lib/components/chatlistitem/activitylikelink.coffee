React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Tooltip      = require 'app/components/tooltip'
ProfileText  = require 'app/components/profile/profiletext'


module.exports = class ActivityLikeLink extends React.Component

  @defaultProps =
    tooltip : yes

  getClassName: ->

    classnames(
      'ActivityLikeLink' : yes
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

    return null  unless @props.tooltip

    { actorsCount } = @props.interactions.like

    return null  unless actorsCount

    <Tooltip>
      {@renderTooltipItems()}
    </Tooltip>


  render: ->

    <a className={@getClassName()} onClick={ @bound 'onClick' } >
      {@props.children}
      {@renderTooltip()}
    </a>



