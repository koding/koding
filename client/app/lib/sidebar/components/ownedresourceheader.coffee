React = require 'app/react'
cx = require 'classnames'

Link = require 'app/components/common/link'

UnreadCount = require './unreadcount'
MenuIcon = require './menuicon'

module.exports = class OwnedResourceHeader extends React.Component

  render: ->

    { title, onTitleClick, unreadCount, onMenuIconClick, selected } = @props

    className = cx ['SidebarSection-header', {
      'unread': !!unreadCount
      'active': !!selected
    }]

    <header className={className}>
      <h4 className='SidebarSection-headerTitle'>

        <Link onClick={onTitleClick}>{title}</Link>

        {onMenuIconClick and
          <MenuIcon onClick={onMenuIconClick} />}

        {!!unreadCount and
          <UnreadCount count={unreadCount} />}

      </h4>
    </header>
