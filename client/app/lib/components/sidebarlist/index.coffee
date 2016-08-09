React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'

require './styl/sidebarlistitem.styl'

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

    { itemComponent: Component, selectedId, threads, componentProp } = @props

    threads.toList().map (thread) ->
      channel = thread.get 'channel'
      id      = channel.get 'id'

      <Component key={id} active={id is selectedId} channel={channel} />


  render: ->
    <div className={classnames 'SidebarList', @props.className}>
      {@renderChildren()}
    </div>
