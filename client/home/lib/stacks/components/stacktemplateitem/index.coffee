kd = require 'kd'
_ = require 'lodash'
$ = require 'jquery'
React = require 'app/react'
TimeAgo = require 'app/components/common/timeago'
UnreadCount = require 'app/components/sidebarmachineslistitem/unreadcount'
getBoundingClientReact = require 'app/util/getBoundingClientReact'
StackUpdatedWidget = require 'app/components/sidebarstacksection/stackupdatedwidget'
isAdmin = require 'app/util/isAdmin'
whoami = require 'app/util/whoami'
isDefaultTeamStack = require 'app/util/isdefaultteamstack'

module.exports = class StackTemplateItem extends React.Component

  constructor: ->

    super

    @state        =
      coordinates :
        left      : 0
        top       : 0
      showWidget  : no


  componentWillReceiveProps: (nextProps) ->

    nextStackUnreadCount = @getStackUnreadCount nextProps.stack
    @setState { showWidget : yes }  if nextStackUnreadCount > @getStackUnreadCount()

    @setCoordinates()


  componentDidMount: ->

    $('.kdscrollview').on 'scroll', @bound 'scrollOnPage'
    @setCoordinates()


  componentWillUnmount: ->
    $('.kdscrollview').off 'scroll', @bound 'scrollOnPage'


  scrollOnPage: -> _.debounce =>
    @setState({ showWidget: no })
  , 500, { leading: yes, trailing: no }


  setCoordinates: ->

    return  unless @refs.stackTemplateItem

    coordinates = getBoundingClientReact @refs.stackTemplateItem
    @setState { coordinates: coordinates }


  renderButton: ->

    { onAddToSidebar, onRemoveFromSidebar, isVisibleOnSidebar, onCloneFromDashboard, template } = @props

    if onCloneFromDashboard and template.get('originId') isnt whoami()._id
      <a href="#" className="HomeAppView--button primary" onClick={onCloneFromDashboard}>CLONE STACK</a>
    else

      if isVisibleOnSidebar
        <a href="#" className="HomeAppView--button primary" onClick={onRemoveFromSidebar}>REMOVE FROM SIDEBAR</a>
      else
        <a href="#" className="HomeAppView--button primary" onClick={onAddToSidebar}>ADD TO SIDEBAR</a>


  renderCloneButton: ->

    { template, onCloneFromDashboard } = @props
    return  if template.get('accessLevel') is 'private'
    return  if template.get('originId') is whoami()._id



  getStackUnreadCount: (stack = @props.stack) ->

    stack?.getIn [ '_revisionStatus', 'status', 'code' ]


  renderUnreadCount: ->

    return null  unless @getStackUnreadCount()

    <UnreadCount
      count={@getStackUnreadCount()}
      onClick={@bound 'handleUnreadCountClick'} />


  handleUnreadCountClick: ->

    @setCoordinates()
    @setState { showWidget: yes }


  onWidgetClose: ->

    @setState { showWidget: no }


  renderStackUpdatedWidget: ->

    { coordinates, showWidget } = @state

    return null  unless @getStackUnreadCount()
    return null  if not coordinates.left and coordinates.top

    coordinates.top = coordinates.top - 160
    coordinates.left = coordinates.left - 22

    <StackUpdatedWidget
      className='StackTemplate'
      coordinates={coordinates}
      stack={@props.stack}
      visible={showWidget}
      onClose={@bound 'onWidgetClose'}
    />

  renderDisabledStack: (stack, onOpen) ->

    <div className='HomeAppViewListItem StackTemplateItem'>
      <a
        ref='stackTemplateItem'
        className='HomeAppViewListItem-label disabled'
        onClick={onOpen}>
        { makeTitle { stack } }
      </a>
      <div className='HomeAppViewListItem-description disabled'>
        Last updated <TimeAgo from={stack.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>

  renderTags: ->

    { template, onCloneFromDashboard } = @props

    if isDefaultTeamStack template.get '_id'
      <div className='tag default'>DEFAULT</div>
    else if onCloneFromDashboard and template.get('accessLevel') is 'group'
      <div className='tag shared'>SHARED</div>
    else
      null


  render: ->

    { template, stack, onOpen } = @props

    return @renderDisabledStack(stack, onOpen)  if stack?.get 'disabled'
    return null  unless template

    editorUrl = "/Stack-Editor/#{template.get '_id'}"

    <div className='HomeAppViewListItem StackTemplateItem'>
      <div className='HomeAppViewListItem-label--wrapper'>
        <a
          ref='stackTemplateItem'
          href={editorUrl}
          className='HomeAppViewListItem-label'
          onClick={onOpen}>
          { makeTitle { template, stack } }
        </a>
        {@renderUnreadCount()}
        {@renderTags()}
      </div>
      {@renderStackUpdatedWidget()}
      <div className='HomeAppViewListItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>


makeTitle = ({ template, stack }) ->

  title = _.unescape template?.get 'title'

  return title  unless stack
  if stack.getIn(['config', 'oldOwner'])
    title = stack.get 'title'

  return "#{title}"
