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

    if @props.stack?.getUnreadCount() < nextProps.stack?.getUnreadCount()
      @setState { showWidget: yes }

    @setCoordinates()


  componentDidMount: ->

    $('.kdscrollview').on 'scroll', @bound 'onScrollPage'
    @setCoordinates()


  componentWillUnmount: ->
    $('.kdscrollview').off 'scroll', @bound 'onScrollPage'


  onScrollPage: -> _.debounce =>
    @setState({ showWidget: no })
  , 500, { leading: yes, trailing: no }


  setCoordinates: ->

    return  unless @refs.stackTemplateItem

    coordinates = getBoundingClientReact @refs.stackTemplateItem
    @setState { coordinates: coordinates }


  renderButton: ->

    { onAddToSidebar, onRemoveFromSidebar,
      isVisibleOnSidebar, onCloneFromDashboard, template } = @props

    if onCloneFromDashboard and not template.isMine()
      <ItemLink
        onClick={onCloneFromDashboard}
        title='CLONE STACK' />

    else if isVisibleOnSidebar
      <ItemLink
        onClick={onRemoveFromSidebar}
        title='REMOVE FROM SIDEBAR' />
    else
      <ItemLink
        onClick={onAddToSidebar}
        title='ADD TO SIDEBAR' />


  renderUnreadCount: ->

    return null  unless count = @props.stack?.getUnreadCount()

    <UnreadCount count={count} onClick={@bound 'handleUnreadCountClick'} />


  handleUnreadCountClick: ->

    @setCoordinates()
    @setState { showWidget: yes }


  onWidgetClose: ->

    @setState { showWidget: no }


  renderStackUpdatedWidget: ->

    { coordinates, showWidget } = @state

    return null  unless @props.stack?.getUnreadCount()
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
        onClick={onOpen}
        children={makeTitle({ stack })} />

      <div className='HomeAppViewListItem-description disabled'>
        Last Updated <TimeAgo from={stack.meta.modifiedAt}
      </div>

      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>


  renderTags: ->

    { template, onCloneFromDashboard } = @props

    if isDefaultTeamStack template.getId()
      <div className='tag default'>DEFAULT</div>
    else if onCloneFromDashboard and template.accessLevel is 'group'
      <div className='tag shared'>SHARED</div>
    else
      null


  render: ->

    { template, stack, onOpen } = @props

    if stack?.disabled
      return renderDisabledStack stack, onOpen

    if not template
      return null

    editorUrl = "/Stack-Editor/#{template.getId()}"

    <div className='HomeAppViewListItem StackTemplateItem'>
      <div className='HomeAppViewListItem-label--wrapper'>
        <a
          ref='stackTemplateItem'
          href={editorUrl}
          className='HomeAppViewListItem-label'
          onClick={onOpen}
          children={ makeTitle { template, stack } }>
        </a>
        {@renderUnreadCount()}
        {@renderTags()}
      </div>
      {@renderStackUpdatedWidget()}
      <div className='HomeAppViewListItem-description'>
        Last updated <TimeAgo from={template.meta.modifiedAt} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>


makeTitle = ({ template, stack }) ->

  title = _.unescape template?.title

  return title  unless stack

  if stack.getOldOwner()
    title = stack.get 'title'

  return "#{title}"


ItemLink = ({ onClick, title }) ->
  <a
    href="#"
    className="HomeAppView--button primary"
    onClick={onClick}
    children={title} />
