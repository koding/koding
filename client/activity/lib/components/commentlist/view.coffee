kd              = require 'kd'
React           = require 'kd-react'
Link            = require 'app/components/common/link'
immutable       = require 'immutable'
CommentListItem = require 'activity/components/commentlistitem'


module.exports = class CommentListView extends React.Component

  @propTypes =
    repliesCount    : React.PropTypes.number
    channelId       : React.PropTypes.string
    onMentionClick  : React.PropTypes.func.isRequired
    showMoreComment : React.PropTypes.func.isRequired
    comments        : React.PropTypes.instanceOf immutable.Map


  defaultProps =
    repliesCount   : 0
    channelId      : null
    comments       : immutable.Map()


  renderShowMoreComments: ->

    { repliesCount } = @props

    return null  unless repliesCount
    return null  if repliesCount <= @props.comments.size

    commentSize = @props.comments.size
    repliesText = ""

    if repliesCount is commentSize + 1
      repliesText = "Show previous 1 reply"
    else if repliesCount > commentSize + 1 and (repliesCount - commentSize) < 11
      repliesText = "Show previous #{repliesCount - commentSize} replies"
    else
      repliesText = "Show 10 of #{repliesCount - commentSize} replies"

    <Link onClick={ @props.showMoreComment } className='CommentList-showMoreComment'>{repliesText}</Link>


  renderList: ->

    @props.comments.toList().map (comment) =>
      <CommentListItem.Container
        comment        = { comment }
        key            = { comment.get 'id' }
        channelId      = { @props.channelId }
        onMentionClick = { @props.onMentionClick } />


  render: ->

    <div className='CommentList'>
      {@renderShowMoreComments()}
      {@renderList()}
    </div>
