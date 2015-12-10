kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
Avatar               = require 'app/components/profile/avatar'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
classnames           = require 'classnames'
MessageLink          = require 'activity/components/messagelink'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
MessageLikeSummary   = require 'activity/components/common/messagelikesummary'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
toImmutable          = require 'app/util/toImmutable'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'
ActivityFlux         = require 'activity/flux'
CommentList          = require 'activity/components/commentlist'
fetchAccount         = require 'app/util/fetchAccount'
whoami               = require 'app/util/whoami'
ActivitySharePopup   = require 'activity/components/activitysharepopup'

module.exports = class FeedItem extends React.Component

  @defaultProps =
    message: immutable.Map()

  constructor: (props) ->

    super props

    @state =
      comment      : ''
      focusOnInput : no
      isPopupOpen  : no


  shouldComponentUpdate: (nextProps, nextState) ->

    return @props.message isnt nextProps.message or @state isnt nextState


  sendComment: (event) ->

    kd.utils.stopDOMEvent event
    textInput = ReactDOM.findDOMNode @refs.textInput
    @setState hasValue: yes  if textInput.value.trim()
    textInput.focus()


  postComment: (event) ->

    kd.utils.stopDOMEvent event

    input = ReactDOM.findDOMNode @refs.textInput
    body  = input.value

    ActivityFlux.actions.message.createComment @props.message.get('id'), body
      .then => @setState { comment: '', hasValue: no }


  toggleSharePopupVisibility: (event) ->

    kd.utils.stopDOMEvent event

    @setState { isPopupOpen: not @state.isPopupOpen }


  getPostButtonClassNames: -> classnames
    'FeedItem-postComment': yes
    'green' : @state.hasValue
    'hidden': not @state.focusOnInput and not @state.hasValue


  onFocus: (event) -> @setState focusOnInput: yes


  onBlur: (event) -> @setState focusOnInput: no


  handleCommentInputChange: (event) ->

    hasValue = no
    value    = event.target.value.trim()
    hasValue = yes  if value
    @setState { hasValue: hasValue, comment: value }


  renderFeedItemSummary: (message) ->

    actorsCount   = message.getIn ['interactions', 'like', 'actorsCount']

    return null  unless actorsCount

    <div className="FeedItem-summary">
      <MessageLikeSummary message={message} />
    </div>


  onMentionClick: (reply) ->

    kd.utils.stopDOMEvent event

    account = reply.get 'account'
    textInput = ReactDOM.findDOMNode @refs.textInput

    fetchAccount account.toJS(), (err, account) =>
      return  unless account

      inputValue = if textInput.value then "#{textInput.value} " else ""
      value      = "#{inputValue}@#{account.profile.nickname} "

      @setState { comment: value, hasValue: yes }, ->
        textInput.focus()


  renderCommentForm: ->

    <div className='FeedItem-commentForm'>
      <AutoSizeTextarea
        ref         = 'textInput'
        onFocus     = { @bound 'onFocus' }
        onBlur      = { @bound 'onBlur' }
        placeholder = 'Type your comment'
        onChange    = { @bound 'handleCommentInputChange' }
        value       = {@state.comment}
        className   = 'FeedItem-commentInput'/>
      <button
        className={@getPostButtonClassNames()}
        onClick={ @bound 'postComment' }>SEND</button>
    </div>


  render: ->

    { message } = @props
    imAccount   = toImmutable({ id: whoami()._id, constructorName: 'JAccount'})

    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper MediaObject">
          <div className="MediaObject-media">
            {makeAvatar message.get 'account'}
          </div>
          <div>
            <span className="FeedItem-authorName">
              {makeProfileLink message.get 'account'}
            </span>
            <MessageLink message={message}>
              <TimeAgo from={message.get 'createdAt'} className='FeedItem-date'/>
            </MessageLink>
          </div>
        </div>
      </header>
      <section className="FeedItem-body">
        <div className="FeedItem-bodyContentWrapper">
          <MessageBody message={message} />
        </div>
      </section>
      <footer className="FeedItem-footer">
        <div className="FeedItem-footerActionContainer">
          <ActivityLikeLink
            tooltip={no}
            messageId={message.get('id')}
            interactions={message.get('interactions').toJS()}>
            Like
          </ActivityLikeLink>
          <Link onClick={@bound 'sendComment'}>Comment</Link>
          <Link onClick={@bound 'toggleSharePopupVisibility'}>Share</Link>
          <ActivitySharePopup
            url = "Activity/Post/#{message.get('slug')}"
            className='FeedItem-sharePopup'
            isOpened={@state.isPopupOpen}/>
        </div>
        {@renderFeedItemSummary(message)}
        <div className='FeedItem-comment'>
          <div className='FeedItem-commentList'>
            <CommentList
              repliesCount={ @props.message.get 'repliesCount' }
              comments={ @props.message.get 'replies' }
              onMentionClick={@bound 'onMentionClick'}/>
          </div>
          <div className="MediaObject-media">
            {makeAvatar imAccount}
          </div>
          {@renderCommentForm()}
        </div>
      </footer>
    </div>


makeComments = (count) ->
  return null  unless count
  <span className="FeedItem-summaryItem FeedItem-replyCount">
    <cite>{count}</cite>
    Comments
  </span>

makeLikes = (count) ->
  return null  unless count
  <span className="FeedItem-summaryItem FeedItem-likeCount">
    <cite>{count}</cite>
    Likes
  </span>


makeTimeAgo = (createdAt) ->
  <Link className="FeedItem-date u-color-light-text">
    <TimeAgo from={createdAt} />
  </Link>

makeProfileLink = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <ProfileText />
  </ProfileLinkContainer>

makeAvatar = (imAccount) ->
  <ProfileLinkContainer origin={imAccount.toJS()}>
    <Avatar className="FeedItem-Avatar" width={35} height={35} />
  </ProfileLinkContainer>



