kd                 = require 'kd'
Link               = require 'app/components/common/link'
React              = require 'kd-react'
classnames         = require 'classnames'
UnreadCount        = require 'app/components/sidebarmachineslistitem/unreadcount'
CreateChannelFlux  = require 'activity/flux/createchannel'


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


  renderHeader: ->

    unreadCount = if @props.unreadCount
    then 'unread'
    else ''

    <header className="SidebarSection-header #{unreadCount}">
      <Link href={@props.titleLink}>
        <h4 className='SidebarSection-headerTitle'>
          {@props.title}
        </h4>
      </Link>
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
