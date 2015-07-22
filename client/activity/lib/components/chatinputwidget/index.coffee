kd       = require 'kd'
React    = require 'kd-react'
TextArea = require 'react-autosize-textarea'

module.exports = class ChatInputWidget extends React.Component

  ENTER = 13

  constructor: (props) ->

    super props

    @state = { value : '' }


  update: (event) ->

    @setState { value: event.target.value }


  onKeyDown: (event) ->

    if event.which is ENTER and not event.shiftKey
      kd.utils.stopDOMEvent event
      @props.onSubmit? { value: @state.value }

      @setState { value: '' }


  onResize: ->

    console.log 'resized'


  render: ->

    <div className='ChatInputWidget'>
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'update' }
        onKeyDown = { @bound 'onKeyDown' }
        onResize  = { @bound 'onResize' }
      />
    </div>
