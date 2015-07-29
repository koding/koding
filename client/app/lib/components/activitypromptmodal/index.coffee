kd            = require 'kd'
React         = require 'kd-react'

module.exports = class ActivityPromptModal extends React.Component

  render: ->
    <div className={kd.utils.curry 'Modal-wrapper', @props.className} ref="ModalWrapper">
      <h2 className="Modal-title">{ @props.title }</h2>
      <button type="button" className="Modal-closeButton" onClick={@props.buttonCloseHandler}></button>
      <div className="Modal-body">{ @props.body }</div>
      <div className="Modal-buttons">
        <button type="button" className="Modal-buttonYES" onClick={@props.buttonYESHandler}>{ @props.buttonYESText }</button>
        <button type="button" className="Modal-buttonOK"  onClick={@props.buttonNOHandler}>{ @props.buttonNOText }</button>
      </div>
    </div>




