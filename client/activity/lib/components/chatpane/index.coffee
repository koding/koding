kd                   = require 'kd'
React                = require 'kd-react'
ChatList             = require 'activity/components/chatlist'
ActivityFlux         = require 'activity/flux'
whoami               = require 'app/util/whoami'
Scroller             = require 'app/components/scroller'
ScrollerMixin        = require 'app/components/scroller/scrollermixin'
Link                 = require 'app/components/common/link'
dateFormat           = require 'dateformat'
remote               = require('app/remote').getInstance()
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
classnames           = require 'classnames'
moment               = require 'moment'

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
    dateString = moment(givenDate).calendar null,
      sameDay  : '[today]'
      lastDay  : '[yesterday]'
      lastWeek : '[last] dddd'
      sameElse : '[on] MMM D'


  getChannelCreatorProfile: (accountId) ->

    remote.cacheable "JAccount", accountId, (err, account)=>
      return @props.createdBy = account  if account


  getCollaborationTooltipClassNames: -> classnames
    'Tooltip-wrapper': yes
    'visible': @props.showCollaborationTooltip


  getIntegrationTooltipClassNames: -> classnames
    'Tooltip-wrapper': yes
    'visible': @props.showIntegrationTooltip


  renderAuthor: ->

    if @props.createdBy._id is whoami()._id
      <strong>you</strong>
    else
      <ProfileLinkContainer origin={@props.createdBy}>
        <ProfileText />
      </ProfileLinkContainer>


  renderProfileLink: ->

    createdAt = @getChannelCreationDate @channel 'createdAt'
    <span>, created by&nbsp;
      {@renderAuthor()} {createdAt}. <br/>
    </span>

  renderChannelName: ->

    channelName = @channel 'name'

    if @channel('typeConstant') is 'privatemessage'
      <div className='ChatPane-channelName'>
        This is a <strong>private</strong> conversation.
      </div>

    else
      return <div className='ChatPane-channelName'>#{channelName}</div>


  renderChannelIntro: ->

    channelName = @channel 'name'

    return null  if @channel('typeConstant') is 'privatemessage'
    return [ "This is the ", <Link onClick=kd.noop>#{channelName}</Link>, " channel", @renderProfileLink() ]



  renderChannelInfoContainer: ->

    return null  unless @props.thread
    @getChannelCreatorProfile @channel 'accountOldId'

    if @props.thread.getIn(['flags', 'reachedFirstMessage']) and @props.createdBy
      channelName = @channel 'name'
      <div className='ChatPane-infoContainer'>
        {@renderChannelName()}
        <div className='ChatPane-channelDescription'>
          {@renderChannelIntro()}
          You can start a collaboration session, or drag and drop  VMs and workspaces here from the sidebar to let anyone in this channel access them.
          (<Link onClick ={ @props.startCollaboration }>Show me how?</Link>)
        </div>
        <div className='ChatPane-actionContainer'>
          <Link className='ChatPane-startCollaborationAction' onClick ={ @props.startCollaboration }>
            Start Collaboration
            <div className={@getCollaborationTooltipClassNames()}><span>Coming soon</span></div>
          </Link>
          <Link className='ChatPane-addIntegrationAction' onClick ={ @props.addIntegration }>
            Add integration
            <div className={@getIntegrationTooltipClassNames()}><span>Coming soon</span></div>
          </Link>
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

