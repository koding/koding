kd                 = require 'kd'
Link               = require 'app/components/common/link'
React              = require 'kd-react'
classnames         = require 'classnames'
CreateChannelFlux  = require 'activity/flux/createchannel'

module.exports = class SidebarSection extends React.Component

  @defaultProps =
    titleLink     : '#'
    title         : ''
    unreadCount   : 0
    secondaryLink : '#'

  renderUnreadCount: ->

    if @props.unreadCount > 0
      <cite className="SidebarListItem-unreadCount --header">{@props.unreadCount}</cite>


  renderSecondaryLink: ->

    return null  unless @props.secondaryLink

    <Link
      className="SidebarSection-secondaryLink"
      href={@props.secondaryLink} />


  renderHeader: ->

    <header className="SidebarSection-header">
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
