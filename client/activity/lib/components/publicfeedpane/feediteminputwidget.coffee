kd               = require  'kd'
React            = require 'kd-react'
ReactDOM         = require 'react-dom'
whoami           = require 'app/util/whoami'
Encoder          = require 'htmlencode'
AutoSizeTextarea = require 'app/components/common/autosizetextarea'
Button           = require 'app/components/common/button'
ActivityFlux     = require 'activity/flux'
KeyboardKeys     = require 'app/util/keyboardKeys'

module.exports = class FeedItemInputWidget extends React.Component

  defaultProps =
    value : ''

  constructor: (props) ->

    super

    @state =
      value     : @props.value
      channelId : null


  componentDidMount: ->

    kd.utils.moveCaretToEnd ReactDOM.findDOMNode @refs.textarea


  onKeyDown: (event) ->

    @props.cancelEdit()  if event.which is KeyboardKeys.ESC


  onChange: (event) -> @setState value: event.target.value


  getValue: -> return @state.value


  render: ->

    firstName   = Encoder.htmlDecode(whoami().profile.firstName)
    placeholder = "Hey #{firstName}, share something interesting or ask a question."

    <div className='FeedInputWidget embedded'>
      <AutoSizeTextarea
        ref='textarea'
        placeholder={ placeholder }
        value={ @state.value }
        onKeyDown={ @bound 'onKeyDown' }
        onChange={ @bound 'onChange' } />
      <div className='FeedInputWidget-buttonBar'>
        <Button
          tabIndex={1}
          className='FeedInputWidget-cancel'
          onClick={ @props.cancelEdit }>CANCEL</Button>
        <Button
          tabIndex={0}
          className='FeedInputWidget-send'
          onClick={ @props.updateMessage }>DONE</Button>
      </div>
    </div>

