kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'


module.exports = class SidebarList extends React.Component

  @defaultProps =
    itemComponent : null
    threads       : immutable.Map()
    selectedId    : null


  renderChildren: ->

    { itemComponent: Component, selectedId, threads, previewCount, componentProp } = @props

    if componentProp is 'SidebarMessagesListItem'
      threads = threads.slice 0, previewCount

    threads.toList().map (thread) ->
      id = thread.getIn ['channel', 'id']
      <Component key={id} active={id is selectedId} thread={thread} />


  render: ->
    <div className={classnames 'SidebarList', @props.className}>
      {@renderChildren()}
    </div>

