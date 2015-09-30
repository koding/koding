kd                   = require 'kd'
React                = require 'kd-react'
ChatList             = require 'activity/components/chatlist'
ActivityFlux         = require 'activity/flux'
Scroller             = require 'app/components/scroller'
ScrollerMixin        = require 'app/components/scroller/scrollermixin'
Link                 = require 'app/components/common/link'
dateFormat           = require 'dateformat'
remote               = require('app/remote').getInstance()
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class ChatPane extends React.Component

  @defaultProps =
    title         : null
    messages      : null
    isDataLoading : no
    onLoadMore    : kd.noop
    showItemMenu  : yes
    createdBy     : null


  componentWillUpdate: (nextProps, nextState) ->

    return  unless nextProps?.thread

    { thread } = nextProps
    isMessageBeingSubmitted = thread.getIn ['flags', 'isMessageBeingSubmitted']
    @shouldScrollToBottom   = yes  if isMessageBeingSubmitted


  onTopThresholdReached: -> @props.onLoadMore()


  channel: (key) -> @props.thread.getIn ['channel', key]


  getChannelCreationDate: (givenDate) ->

    timeFormat     = 'h:MM TT'

    relativeDates  = ["Today", "Yesterday"]
    today          = new Date
    givenDate      = new Date givenDate
    dateDifference = today.getDate() - givenDate.getDate()
    dateString     = relativeDates[dateDifference] or dateFormat givenDate, "mmmm d"
    if relativeDates[dateDifference]
      dateString     = "#{dateString} at #{dateFormat givenDate, timeFormat}"
    else
      dateString     = "#{dateString}th."


  getChannelCreatorProfile: (accountId) ->

    remote.cacheable "JAccount", accountId, (err, account)=>
      return @props.createdBy = account  if account


  renderProfileLink: ->

    createdAt = @getChannelCreationDate @channel 'createdAt'
    <span>, created by&nbsp;
      <ProfileLinkContainer origin={@props.createdBy}>
        <ProfileText />
      </ProfileLinkContainer> on {createdAt}. <br/>
    </span>


  renderChannelInfoContainer: ->

    return null  unless @props.thread
    @getChannelCreatorProfile @channel 'accountOldId'

    if @props.thread.getIn(['flags', 'reachedFirstMessage']) and @props.createdBy
      channelName = @channel 'name'
      <div className='ChatPane-infoContainer'>
        <div className='ChatPane-channelName'>#{channelName}</div>
        <div className='ChatPane-channelDescription'>
          This is the <Link onClick=kd.noop>#{channelName}</Link> channel
          {@renderProfileLink()}
          You can start a collaboration session, or drag and drop  VMs and workspaces here from the sidebar to let anyone in this channel access them.
          (<Link onClick ={ @props.startCollaboration }>Show me how?</Link>)
        </div>
        <div className='ChatPane-actionContainer'>
          <Link className='ChatPane-startCollaborationAction' onClick ={ @props.startCollaboration }>Start Collaboration</Link>
          <Link className='ChatPane-addIntegrationAction' onClick ={ @props.addIntegration }>Add integration</Link>
          <Link className='ChatPane-inviteOthersAction' onClick ={ @props.inviteOthers }>Invite others</Link>
        </div>
      </div>


  renderBody: ->

    return null  unless @props.messages?.size

    <Scroller
      onTopThresholdReached={@bound 'onTopThresholdReached'}
      ref="scrollContainer">
      {@renderChannelInfoContainer()}
      <ChatList
        isMessagesLoading={@props.thread?.getIn ['flags', 'isMessagesLoading']}
        messages={@props.messages}
        showItemMenu={@props.showItemMenu}
        channelId={@channel 'id'}
        channelName={@channel 'name'}
        unreadCount={@channel 'unreadCount'}
      />
    </Scroller>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        <section className="ChatPane-body" ref="ChatPaneBody">
          {@renderBody()}
          {@props.children}
        </section>
      </section>
    </div>


React.Component.include.call ChatPane, [ScrollerMixin]

