kd = require 'kd'
React = require 'app/react'
cx = require 'classnames'

{ findDOMNode } = require 'react-dom'

Link = require 'app/components/common/link'

StackUpdatedWidget = require './stackupdatedwidget'
UnreadCount = require './unreadcount'
MenuIcon = require './menuicon'

module.exports = class OwnedResourceHeader extends React.Component

  constructor: (props) ->
    super props

    @state = { coordinates: {} }

    @_header = null


  componentDidMount: ->

    if @_header and @props.hasWidget
      kd.utils.defer =>
        rect = findDOMNode(@_header).getBoundingClientRect()

        @setState
          coordinates: { top: rect.top, left: rect.width + rect.left }


  componentWillReceiveProps: (nextProps) ->

    if @_header and nextProps.hasWidget
      kd.utils.defer =>
        rect = findDOMNode(@_header).getBoundingClientRect()

        @setState
          coordinates: { top: rect.top, left: rect.width + rect.left }


  render: ->

    { title, onTitleClick, unreadCount, onMenuIconClick,
      selected, hasWidget, onUnreadCountClick, stack } = @props

    className = cx ['SidebarSection-header', {
      'unread': !!unreadCount
      'active': !!selected
    }]

    if oldOwner = stack?.getOldOwner()
      title = "#{title} (@#{oldOwner})"

    <header ref={(header) => @_header = header} className={className}>
      <h4 className='SidebarSection-headerTitle'>

        <Link onClick={onTitleClick} title={title}>{title}</Link>

        {onMenuIconClick and
          <MenuIcon onClick={onMenuIconClick} />}

        {!!unreadCount and
          <UnreadCount
            onClick={onUnreadCountClick}
            count={unreadCount} />}

        {hasWidget and stack and
          <StackUpdatedWidget
            stack={stack}
            coordinates={@state.coordinates} />}

      </h4>
    </header>
