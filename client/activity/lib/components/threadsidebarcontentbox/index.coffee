kd    = require 'kd'
React = require 'kd-react'
Link  = require 'app/components/common/link'

module.exports = class ThreadSidebarContentBox extends React.Component

  @defaultProps =
    title: 'Default title'
    titleLink: null


  renderHeader: ->

    header = \
      <header className="ThreadSidebarContentBox-header">
        {@props.title}
      </header>

    if @props.titleLink
      <Link href={@props.titleLink}>
        {header}
      </Link>
    else header


  render: ->
    <div className={kd.utils.curry 'ThreadSidebarContentBox', @props.className}>
      {@renderHeader()}
      <section className="ThreadSidebarContentBox-content">
        {@props.children}
      </section>
    </div>


