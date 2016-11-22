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

    unless @props.originalTemplateUpdate
      <UnreadCount
        count={@props.unreadCount}
        onClick={@bound 'handleUnreadCountClick'} />
    else
      <UnreadCount
        count={1}
        onClick={@bound 'handleOpenStackEditor'} />


  handleOpenStackEditor: ->
    kd.singletons.router.handleRoute "/Stack-Editor/#{@props.baseStackId}"


  handleUnreadCountClick: ->
    @props.unreadCountClickHandler()


  renderSecondaryLink: ->

    return null  unless @props.secondaryLink

    <Link
      className="SidebarSection-secondaryLink"
      href={@props.secondaryLink} />


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
