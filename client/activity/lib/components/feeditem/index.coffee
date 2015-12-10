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
      comment            : ''
      focusOnInput       : no
      isSharePopupOpened : no

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


    kd.singletons.router.handleRoute "/Channels/Public/summary/#{@props.message.get 'slug'}"

  render: ->
    { message } = @props
    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper">
          {makeProfileLink message.get 'account'}
          {makeTimeAgo message.get 'createdAt'}
        </div>
      </header>
      <section className="FeedItem-body">
        <div className="FeedItem-bodyContentWrapper">
          <MessageBody source={message.get 'body'} />
        </div>
      </section>
      <footer className="FeedItem-footer">
        <div className="FeedItem-summary">
          {makeLikes message.getIn ['interactions', 'like', 'actorsCount']}
          {makeComments message.get 'repliesCount'}
        </div>
        <div className="FeedItem-footerActionContainer">
          <button
            onClick={@bound 'onConversationButtonClick'}
            className="Button Button--info">View Conversation</button>
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



