kd = require 'kd'
React = require 'kd-react'
classnames = require 'classnames'


module.exports = class SidebarSection extends React.Component

  renderHeader: ->
    <h4 className="SidebarSection-headerTitle">{@props.title}</h4>

  render: ->
    <section className={classnames 'SidebarSection', @props.className}>
      <header className="SidebarSection-header">
        {@renderHeader()}
      </header>
      <div className="SidebarSection-body">
        {@props.children}
      </div>
    </section>
