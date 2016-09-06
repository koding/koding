kd               = require  'kd'
React            = require 'kd-react'
whoami           = require 'app/util/whoami'
Encoder          = require 'htmlencode'
AutoSizeTextarea = require 'app/components/common/autosizetextarea'
Button           = require 'app/components/common/button'


module.exports = class FeedItemInputWidget extends React.Component

  @propTypes =
    value         : React.PropTypes.string
    onChange      : React.PropTypes.func
    channelId     : React.PropTypes.string
    onKeyDown     : React.PropTypes.func
    cancelEdit    : React.PropTypes.func
    updateMessage : React.PropTypes.func

  @defaultTypes =
    value         : ''
    onChange      : kd.noop
    channelId     : ''
    onKeyDown     : kd.noop
    cancelEdit    : kd.noop
    updateMessage : kd.noop


  render: ->

    firstName   = Encoder.htmlDecode(whoami().profile.firstName)
    placeholder = "Hey #{firstName}, share something interesting or ask a question."

    <div className='FeedInputWidget embedded'>
      <AutoSizeTextarea
        ref='textarea'
        placeholder={ placeholder }
        value={ @props.value }
        onKeyDown={ @props.onKeyDown }
        onChange={ @props.onChange } />
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
