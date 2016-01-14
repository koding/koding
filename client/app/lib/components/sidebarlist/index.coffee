kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'

module.exports = class SidebarList extends React.Component

  @propTypes =
    itemComponent : React.PropTypes.func
    selectedId    : React.PropTypes.string
    threads       : React.PropTypes.instanceOf immutable.Map

  @defaultProps =
    itemComponent : null
    selectedId    : null
    threads       : immutable.Map()


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
