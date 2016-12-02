kd                 = require 'kd'
Link               = require 'app/components/common/link'
React              = require 'app/react'
isKoding           = require 'app/util/isKoding'
classnames         = require 'classnames'
UnreadCount        = require 'app/components/sidebarmachineslistitem/unreadcount'

require './styl/sidebarsection.styl'

module.exports = class SidebarSection extends React.Component

  @defaultProps =
    titleLink                 : '#'
    title                     : ''
    unreadCount               : 0
    secondaryLink             : '#'
    unreadCountClickHandler   : kd.noop


  renderUnreadCount: ->
    <UnreadCount
      count={@props.unreadCount}
      onClick={@bound 'handleUnreadCountClick'} />


  handleUnreadCountClick: ->
    @props.unreadCountClickHandler()


  renderSecondaryLink: ->

    return null  unless @props.secondaryLink

    <Link
      className="SidebarSection-secondaryLink"
      href={@props.secondaryLink} />


  renderMenuIcon: ->

    return null  unless @props.onMenuIconClick

    <div onClick={@props.onMenuIconClick} className='menu-icon'></div>


  renderHeader: ->

    return null  unless @props.title

    unreadCount = if @props.unreadCount
    then 'unread'
    else ''

    linkProps = { }
    if @props.onTitleClick
      linkProps.onClick = @props.onTitleClick

    <header className="SidebarSection-header #{unreadCount}">
      <h4 className='SidebarSection-headerTitle'>
        <Link {...linkProps}>{@props.title}</Link>
      </h4>
      {@renderMenuIcon()}
      {@renderSecondaryLink()}
      {@renderUnreadCount()}
    </header>


  render: ->

    <section className={classnames 'SidebarSection', @props.className}>
      {@renderHeader()}
      <div className='SidebarSection-body'>
        {@props.children}
      </div>
    </section>
