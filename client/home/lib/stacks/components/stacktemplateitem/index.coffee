kd = require 'kd'
_ = require 'lodash'
React = require 'kd-react'
TimeAgo = require 'app/components/common/timeago'
UnreadCount = require 'app/components/sidebarmachineslistitem/unreadcount'
getBoundingClientReact = require 'app/util/getBoundingClientReact'
StackUpdatedWidget = require 'app/components/sidebarstacksection/stackupdatedwidget'

module.exports = class StackTemplateItem extends React.Component

  constructor: ->

    super

    @state        =
      coordinates :
        left      : 0
        top       : 0
      showWidget  : no

    $('.kdscrollview').on 'scroll', @bound 'scrollOnPage'


  componentWillReceiveProps: -> @setCoordinates()


  componentDidMount: -> @setCoordinates()

  scrollOnPage: ->

    @setState { showWidget: no }


  setCoordinates: ->

    return  unless @refs.stackTemplateItem

    coordinates = getBoundingClientReact @refs.stackTemplateItem
    @setState { coordinates: coordinates }


  renderButton: ->

    { template, onAddToSidebar, onRemoveFromSidebar, isVisibleOnSidebar } = @props

    if isVisibleOnSidebar
      <a href="#" className="HomeAppView--button primary" onClick={onRemoveFromSidebar}>REMOVE FROM SIDEBAR</a>
    else
      <a href="#" className="HomeAppView--button primary" onClick={onAddToSidebar}>ADD TO SIDEBAR</a>


  getStackUnreadCount: ->

    @props.stack?.getIn [ '_revisionStatus', 'status', 'code' ]


  renderUnreadCount: ->

    return null  unless @getStackUnreadCount()

    <UnreadCount
      count={@getStackUnreadCount()}
      onClick={@bound 'handleUnreadCountClick'} />


  handleUnreadCountClick: ->

    @setCoordinates()
    @setState { showWidget: yes }


  renderStackUpdatedWidget: ->

    { coordinates, showWidget } = @state

    return null  unless @getStackUnreadCount()
    return null  if not coordinates.left and coordinates.top

    coordinates.top = coordinates.top - 156
    <StackUpdatedWidget className={'stackTemplate'} coordinates={coordinates} stack={@props.stack} show={showWidget} />


  render: ->

    { template, stack, onOpen } = @props

    return null  unless template

    editorUrl = "/Stack-Editor/#{template.get '_id'}"

    <div className='HomeAppViewListItem StackTemplateItem'>
      <a
        ref='stackTemplateItem'
        href={editorUrl}
        className='HomeAppViewListItem-label'
        onClick={onOpen}>
        { makeTitle { template, stack } }
      </a>
      {@renderUnreadCount()}
      {@renderStackUpdatedWidget()}
      <div className='HomeAppViewListItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>

makeTitle = ({ template, stack }) ->

  title = _.unescape template.get 'title'

  return title  unless stack
  return title  unless oldOwner = stack.getIn(['config', 'oldOwner'])

  return "#{title} (@#{oldOwner})"

