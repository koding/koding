kd                   = require 'kd'
React                = require 'kd-react'
Link                 = require 'app/components/common/link'
TimeAgo              = require 'app/components/common/timeago'
immutable            = require 'immutable'
MessageLink          = require 'activity/components/messagelink'
MessageBody          = require 'activity/components/common/messagebody'
ProfileText          = require 'app/components/profile/profiletext'
ActivityFlux         = require 'activity/flux'
Comments             = require 'activity/components/comments'
ActivitySharePopup   = require 'activity/components/activitysharepopup'
Avatar               = require 'app/components/profile/avatar'
MessageItemMenu      = require 'activity/components/messageitemmenu'
classnames           = require 'classnames'
FeedItemInputWidget  = require './feediteminputwidget'
MessageLikeSummary   = require 'activity/components/common/messagelikesummary'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ActivityLikeLink     = require 'activity/components/chatlistitem/activitylikelink'

module.exports = class FeedItem extends React.Component

  @defaultProps =
    channelId : null
    message   : immutable.Map()

  constructor: (props) ->

    super props

    @state = { isPopupOpen : no }


  shouldComponentUpdate: (nextProps, nextState) ->

    return @props.message isnt nextProps.message or @state isnt nextState


  handleCommentLinkClick: (event) ->

    kd.utils.stopDOMEvent event

    @refs.Comments.focusCommentInput()


  toggleSharePopupVisibility: (event) ->

    kd.utils.stopDOMEvent event

    @setState { isPopupOpen: not @state.isPopupOpen }


  updateMessage: ->

    value     = @refs.editInputWidget.getValue().trim()
    messageId = @props.message.get '_id'
    { message } = ActivityFlux.actions

    message.unsetMessageEditMode messageId, @props.channelId
    message.editMessage messageId, value



  renderFeedItemMenu: ->

    <MessageItemMenu message={@props.message}/>

  render: ->

    { message } = @props
    likeText = if message.getIn ['interactions', 'like',  'isInteracted'] then 'Unlike' else 'Like'

    <div className={kd.utils.curry 'FeedItem', @props.className}>
      <header className="FeedItem-header">
        <div className="FeedItem-headerContentWrapper MediaObject">
          <div className="MediaObject-media">
            <ProfileLinkContainer origin={message.get('account').toJS()}>
              <Avatar className="FeedItem-Avatar" width={35} height={35} />
            </ProfileLinkContainer>
          </div>
          <div>
            <span className="FeedItem-authorName">
              <ProfileLinkContainer origin={message.get('account').toJS()}>
                <ProfileText />
              </ProfileLinkContainer>
            </span>
            <MessageLink message={message}>
              <TimeAgo from={message.get 'createdAt'} className='FeedItem-date'/>
            </MessageLink>
          </div>
        </div>
        {@renderFeedItemMenu()}
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
            {likeText}
          </ActivityLikeLink>
          <Link onClick={@bound 'handleCommentLinkClick'}>Comment</Link>
          <Link onClick={@bound 'toggleSharePopupVisibility'}>Share</Link>
          <ActivitySharePopup
            url = "Activity/Post/#{message.get('slug')}"
            className='FeedItem-sharePopup'
            isOpened={@state.isPopupOpen} />
        </div>
        <MessageLikeSummary message={message} className="FeedItem-summary" />
        <Comments ref='Comments' message={ @props.message } />
      </footer>
    </div>

