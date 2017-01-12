React = require 'react'

Message = require 'lab/Message'
Icon = require 'lab/Icon'

styles = require './headermessage.stylus'

module.exports = class HeaderMessage extends React.Component

  constructor: (props) ->
    super props
    @state = { isClosed: no }


  onButtonClick: ->
    @props.onButtonClick()
    @setState { isClosed: yes }


  onCloseClick: ->
    @setState { isClosed: yes }


  render: ->

    return <span />  if @state.isClosed or not @props.visible

    icons =
      danger: DangerIcon

    { title, type, description, buttonTitle } = @props

    <div className={styles.main}>
      <Message
        type={type}
        title={title}
        IconComponent={icons[type]}
        description={description}
        onCloseClick={@onCloseClick.bind this}
        buttonTitle={buttonTitle}
        onButtonClick={@onButtonClick.bind this} />
    </div>


DangerIcon = ->

  one = require 'app/sprites/1x/danger.png'
  two = require 'app/sprites/2x/danger.png'

  <Icon 1x={one} 2x={two} />
