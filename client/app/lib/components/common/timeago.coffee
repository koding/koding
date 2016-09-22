kd      = require 'kd'
React   = require 'app/react'
timeago = require 'timeago'

module.exports = class TimeAgo extends React.Component

  @propTypes =
    from : React.PropTypes.string.isRequired

  @defaultProps =
    className : ''

  constructor: (props) ->

    super props

    now = new Date

    @state =
      from        : @props.from or now
      lastUpdated : now


  componentDidMount: ->

    @_interval = kd.utils.repeat 60000, => @setState { lastUpdated: new Date }


  componentWillUnmount: ->

    kd.utils.killRepeat @_interval


  render: ->

    <span className={kd.utils.curry "u-color-light-text", @props.className}>
      <time>{timeago @state.from}</time>
    </span>
