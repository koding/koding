kd = require 'kd'
globals = require 'globals'
React = require 'kd-react'
Link  = require 'app/components/common/link'

module.exports = class ShareLinkView extends React.Component

  @propTypes =
    url: React.PropTypes.string.isRequired


  constructor: (props) ->

    super props

    @state = { tooltipVisible: no }


  onLinkClick: ->

    @setState { tooltipVisible: not @state.tooltipVisible }


  selectToCopy: ->

    copyEl = document.querySelectorAll('.ShareLink-tooltip > div > span')[0]
    kd.utils.selectText copyEl

    try
      copied = document.execCommand 'copy'
      throw 'couldn\'t copy'  unless copied
    catch
      hintEl = document.querySelectorAll('.ShareLink-tooltip > div > i')[0]
      key    = if globals.os is 'mac' then 'Cmd + C' else 'Ctrl + C'

      hintEl.innerHTML = "Hit #{key} to copy!"


  renderTooltip: ->

    return  unless @state.tooltipVisible


    <div ref={@bound 'selectToCopy'} className='ShareLink-tooltip'>
      <div>
        <i>Copied to clipboard</i>
        <cite></cite>
        <span>{@props.url}</span>
      </div>
    </div>


  render: ->
    <div className="ShareLink">
      <Link onClick={@bound 'onLinkClick'}>Get Share Link!</Link>
      {@renderTooltip()}
    </div>


