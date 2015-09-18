kd                = require 'kd'
React             = require 'kd-react'

module.exports = class ThreadHeader extends React.Component

  @defaultProps = { thread: null }


  channel: (key) -> @props.thread?.getIn ['channel', key]


  renderChildren: ->

    React.Children.map @props.children, (child) ->
      <span className="ThreadHeader-navLink">
        {child}
      </span>


  render: ->
    return null  unless @props.thread

    <div className="ThreadHeader">
      <div className="ThreadHeader-navContainer">
        {@renderChildren()}
      </div>
    </div>


