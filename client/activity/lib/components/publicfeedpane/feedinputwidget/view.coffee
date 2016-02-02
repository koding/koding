kd                     = require  'kd'
React                  = require 'kd-react'
whoami                 = require 'app/util/whoami'
Button                 = require 'app/components/common/button'
Encoder                = require 'htmlencode'
Preview                = require './preview'
KeyboardKeys           = require 'app/constants/keyboardKeys'
ActivityFlux           = require 'activity/flux'
AutoSizeTextarea       = require 'app/components/common/autosizetextarea'

module.exports = class FeedInputWidget extends React.Component

  @propTypes =
    value       : React.PropTypes.string
    onClick     : React.PropTypes.func
    onSubmit    : React.PropTypes.func
    onChange    : React.PropTypes.func
    onKeyDown   : React.PropTypes.func
    previewMode : React.PropTypes.bool

  @defaultProps =
    value       : ''
    onClick     : kd.noop
    onSubmit    : kd.noop
    onChange    : kd.noop
    onKeyDown   : kd.noop
    previewMode : no

  render: ->

    firstName   = Encoder.htmlDecode(whoami().profile.firstName)
    placeholder = "Hey #{firstName}, share something interesting or ask a question."

    <div className = 'FeedInputWidget'>
      <AutoSizeTextarea
        ref         = 'InputWidget'
        value       = { @props.value }
        onChange    = { @props.onChange }
        onKeyDown   = { @props.onKeyDown }
        placeholder = { placeholder }
         />
      <div className = 'FeedInputWidget-buttonBar'>
        <Button
          onClick   = { @props.toggleMarkdownPreviewMode }
          tabIndex  = { 1 }
          className = 'FeedInputWidget-preview' />
        <Button
          onClick   = { @props.onSubmit }
          tabIndex  = { 0 }
          className = 'FeedInputWidget-send' >SEND</Button>
      </div>
      <Preview
        ref                       = 'Preview'
        value                     = { @props.value }
        previewMode               = { @props.previewMode }
        toggleMarkdownPreviewMode = { @props.toggleMarkdownPreviewMode }/>
    </div>
