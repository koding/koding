kd                     = require  'kd'
React                  = require 'kd-react'
whoami                 = require 'app/util/whoami'
Encoder                = require 'htmlencode'
AutoSizeTextarea       = require 'app/components/common/autosizetextarea'
Button                 = require 'app/components/common/button'
ActivityFlux           = require 'activity/flux'
FeedInputWidgetPreview = require './feedinputwidgetpreview'

module.exports = class FeedInputWidget extends React.Component

  constructor: (props) ->

    super

    @state =
      value       : ''
      previewMode : no


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onResize: ->


  onChange: (event) -> @setState value: event.target.value


  toggleMarkdownPreviewMode: (event) -> @setState previewMode: not @state.previewMode


  onSubmit: (event) ->

    kd.utils.stopDOMEvent event

    value = @state.value.trim()

    return  unless value

    ActivityFlux.actions.message.createMessage @channel('id'), value
      .then =>
        @setState { value: '', previewMode: no }


  render: ->

    firstName   = Encoder.htmlDecode(whoami().profile.firstName)
    placeholder = "Hey #{firstName}, share something interesting or ask a question."

    <div className='FeedInputWidget'>
      <i></i>
      <AutoSizeTextarea
        placeholder={placeholder}
        value={@state.value}
        onChange={@bound 'onChange'}
        onResize={ @bound 'onResize' }
        />
      <div className='FeedInputWidget-buttonBar'>
        <Button
          tabIndex={1}
          className='FeedInputWidget-preview'
          onClick={ @bound 'toggleMarkdownPreviewMode' } />
        <Button
          tabIndex={0}
          className='FeedInputWidget-send'
          onClick={ @bound 'onSubmit' }>SEND</Button>
      </div>
      <FeedInputWidgetPreview
        value={ @state.value }
        previewMode={ @state.previewMode }
        toggleMarkdownPreviewMode={ @bound 'toggleMarkdownPreviewMode' }/>
    </div>

