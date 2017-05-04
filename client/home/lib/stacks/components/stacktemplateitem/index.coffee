_ = require 'lodash'
$ = require 'jquery'
kd = require 'kd'
React = require 'app/react'
cx = require 'classnames'

isAdmin = require 'app/util/isAdmin'
whoami = require 'app/util/whoami'
isDefaultTeamStack = require 'app/util/isdefaultteamstack'
getBoundingClientReact = require 'app/util/getBoundingClientReact'

TimeAgo = require 'app/components/common/timeago'
UnreadCount = require 'app/components/sidebarmachineslistitem/unreadcount'
StackUpdatedWidget = require 'app/sidebar/components/stackupdatedwidget'


module.exports = class StackTemplateItem extends React.Component

  constructor: ->

    super

    @state =
      widgetVisible: no
      coordinates: { left: 0, top: 0 }


  componentWillReceiveProps: (nextProps) ->

    if @props.stack?.getUnreadCount() < nextProps.stack?.getUnreadCount()
      @setState { widgetVisible: yes }

    @setCoordinates()


  componentDidMount: ->

    $('.kdscrollview').on 'scroll', @bound 'onScrollPage'
    @setCoordinates()


  componentWillUnmount: ->
    $('.kdscrollview').off 'scroll', @bound 'onScrollPage'


  onScrollPage: -> _.debounce =>
    @setState({ widgetVisible: no })
  , 500, { leading: yes, trailing: no }


  setCoordinates: ->

    return  unless @refs.stackTemplateItem

    coordinates = getBoundingClientReact @refs.stackTemplateItem
    @setState { coordinates: coordinates }


  renderButton: ->

    { onAddToSidebar, onRemoveFromSidebar, canCreateStacks
      isVisibleOnSidebar, onCloneFromDashboard, template } = @props

    if onCloneFromDashboard and not template.isMine()
      <ItemLink
        disabled={not canCreateStacks}
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


  canClone: ->
    { canCreateStacks, template, onCloneFromDashboard } = @props

    return not onCloneFromDashboard or template.isMine() or canCreateStacks


  renderCloningDisabledMessage: ->

    { canCreateStacks, template, onCloneFromDashboard } = @props

    return null  if @canClone()

    <div className='cloning-disabled-msg'>
      Cloning is disabled for members.
      Please ask one of your admins to enable stack creation permission.
    </div>


  renderUnreadCount: ->

    return null  unless count = @props.stack?.getUnreadCount()

    <UnreadCount count={count} onClick={@bound 'handleUnreadCountClick'} />


  handleUnreadCountClick: ->

    @setCoordinates()
    @setState { widgetVisible: yes }


  onWidgetClose: ->

    @setState { widgetVisible: no }


  renderStackUpdatedWidget: ->

    { coordinates, widgetVisible } = @state

    return null  unless widgetVisible
    return null  unless @props.stack?.getUnreadCount()
    return null  if not coordinates.left and coordinates.top

    coordinates.top = coordinates.top - 160
    coordinates.left = coordinates.left - 22

    <StackUpdatedWidget
      className='StackTemplate'
      coordinates={coordinates}
      stack={@props.stack}
      onClose={@bound 'onWidgetClose'}
    />


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

    if stack?.getOldOwner()
      return (
        <DisabledStack
          template={template}
          stack={stack}
          onOpen={onOpen}
        />
      )

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
        {@renderCloningDisabledMessage()}
      </div>
    </div>


DisabledStack = ({ template, stack, onOpen }) ->
  <div className='HomeAppViewListItem StackTemplateItem'>
    <a
      className='HomeAppViewListItem-label disabled'
      onClick={onOpen}
      children={makeTitle({ stack, template })} />

    <div className='HomeAppViewListItem-description disabled'>
      Last Updated <TimeAgo from={stack.meta.modifiedAt} />
    </div>
  </div>


makeTitle = ({ template, stack }) ->

  title = _.unescape template?.title

  return title  unless stack

  if owner = stack.getOldOwner()
    title = "#{title} (@#{owner})"

  return title


ItemLink = ({ onClick, title, disabled }) ->
  className = cx 'HomeAppView--button',
    'primary': not disabled
    'inactive': disabled

  onClick = kd.noop  if disabled

  <a
    href="#"
    className={className}
    onClick={onClick}
    children={title} />
