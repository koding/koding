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


  renderTooltip: ->

    return  unless @state.tooltipVisible

    <div className='ShareLink-tooltip'>
      <div>
        <i>Copied to clipboard</i>
        <cite></cite>{@props.url}
      </div>
    </div>


  render: ->
    <div className="ShareLink">
      <Link onClick={@bound 'onLinkClick'}>Get Share Link!</Link>
      {@renderTooltip()}
    </div>


