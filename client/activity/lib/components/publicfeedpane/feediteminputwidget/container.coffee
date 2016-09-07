kd           = require 'kd'
View         = require './view'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
KeyboardKeys = require 'app/constants/keyboardKeys'

module.exports = class FeedItemInputContainer extends React.Component

  @propTypes =
    value : React.PropTypes.string

  @defaultTypes =
    value : ''

  constructor: (props) ->

    super

    @state =
      value     : @props.value
      channelId : null


  componentDidMount: ->

    kd.utils.moveCaretToEnd ReactDOM.findDOMNode @refs.view.refs.textarea


  onKeyDown: (event) ->

    @props.cancelEdit()  if event.which is KeyboardKeys.ESC


  onChange: (event) -> @setState value: event.target.value


  getValue: -> return @state.value


  render: ->
    <View
      ref           = 'view'
      value         = { @state.value }
      onChange      = { @bound 'onChange' }
      onKeyDown     = { @bound 'onKeyDown' }
      channelId     = { @state.channelId }
      cancelEdit    = { @props.cancelEdit }
      updateMessage = { @props.updateMessage } />
