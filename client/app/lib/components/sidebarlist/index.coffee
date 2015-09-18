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

    { itemComponent: Component, selectedId, threads, previewCount } = @props

    selectedChannelThread = threads.get selectedId
    listCount = 0
    threads = threads.slice 0, previewCount
    isSelectedChannelExistInVisibleThreads = threads.get(selectedId)

    threads.map (thread) ->
      id = thread.getIn ['channel', 'id']
      if isSelectedChannelExistInVisibleThreads
        <Component key={id} active={id is selectedId} thread={thread} />
      else if listCount is 2 and selectedChannelThread
        listCount++
        <Component key={selectedId} active=yes thread={selectedChannelThread} />
      else
        listCount++
        <Component key={id} thread={thread} />


  render: ->
    <div className={classnames 'SidebarList', @props.className}>
      {@renderChildren()}
    </div>

