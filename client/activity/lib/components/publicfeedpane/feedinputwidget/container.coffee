kd                     = require  'kd'
View                   = require './view'
React                  = require 'kd-react'
Button                 = require 'app/components/common/button'
whoami                 = require 'app/util/whoami'
Encoder                = require 'htmlencode'
KeyboardKeys           = require 'app/constants/keyboardKeys'
ActivityFlux           = require 'activity/flux'
AutoSizeTextarea       = require 'app/components/common/autosizetextarea'

module.exports = class FeedInputWidgetContainer extends React.Component

  @propTypes =
    channelId : React.PropTypes.string

  @defaultProps =
    channelId : null


  constructor: (props) ->

    super

    @state =
      value       : ''
      previewMode : no


  onChange: (event) -> @setState value: event.target.value


  toggleMarkdownPreviewMode: (event) -> @setState previewMode: not @state.previewMode


  onSubmit: (event) ->

    kd.utils.stopDOMEvent event

    value = @state.value.trim()

    return  unless value

    ActivityFlux.actions.message.createMessage @props.channelId, value
      .then => @setState { value: '', previewMode: no }


  onKeyDown: (event) ->

    if event.metaKey and event.keyCode is KeyboardKeys.ENTER
      @onSubmit event


  render: ->

    <View
      value                     = { @state.value }
      onSubmit                  = { @bound 'onSubmit' }
      onChange                  = { @bound 'onChange' }
      onKeyDown                 = { @bound 'onKeyDown' }
      previewMode               = { @state.previewMode }
      toggleMarkdownPreviewMode = { @bound 'toggleMarkdownPreviewMode' }
      />