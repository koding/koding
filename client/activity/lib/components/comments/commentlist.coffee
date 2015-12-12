kd              = require 'kd'
React           = require 'kd-react'
Link            = require 'app/components/common/link'
immutable       = require 'immutable'
CommentListItem = require './commentlistitem'

module.exports = class CommentList extends React.Component

  defaultProps=
    repliesCount  : 0
    comments      : immutable.List()
    onMentionClick: kd.noop


  showMoreComment: ->


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

    <Link onClick={ @bound 'showMoreComment' } className='CommentList-showMoreComment'>{repliesText}</Link>


  renderList: ->

    @props.comments.map (comment) =>
      <CommentListItem
        comment={comment}
        key={comment.get 'id'}
        onMentionClick={ @props.onMentionClick } />


  render: ->

    { reply } = @props

    <div className='CommentList'>
      {@renderShowMoreComments()}
      {@renderList()}
    </div>
