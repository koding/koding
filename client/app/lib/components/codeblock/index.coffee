kd = require 'kd'
React = require 'kd-react'
globals = require 'globals'
Tracker = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'
Spinner = require 'app/components/spinner'

module.exports = class CodeBlock extends React.Component

  @propTypes =
    cmd: React.PropTypes.string

  @defaultProps =
    cmd: ''


  constructor: (props) ->

    super props

    key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'

    @state = { key }


  onCMDClick: ->

    codeblock =  @refs.codeblock
    copyToClipboard codeblock

    Tracker.track Tracker.KD_INSTALLED


  render: ->

    className = if @props.cmd then 'block' else 'loading'

    <code className="HomeAppView--code #{className}">
      <Spinner />
      <span ref='codeblock' onClick={@bound 'onCMDClick'}>
        {@props.cmd}
      </span>
      <cite>{@state.key}</cite>
    </code>
