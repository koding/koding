kd = require 'kd'
React = require 'kd-react'
globals = require 'globals'
Tracker = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'


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

     <code className='HomeAppView--code block'>
      <span ref='codeblock' onClick={@bound 'onCMDClick'}>
        {@props.cmd}
      </span>
      <cite>{@state.key}</cite>
    </code>
