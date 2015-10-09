kd     = require 'kd'
React  = require 'kd-react'
Modal  = require 'app/components/modal'

module.exports = class ActivityModal extends React.Component

  @defaultProps =
    onClose                : kd.noop
    onAbort                : kd.noop
    onConfirm              : kd.noop
    onButtonExtraClick     : kd.noop
    closeOnEsc             : yes
    closeOnOutsideClick    : yes
    hasOverlay             : yes
    isOpen                 : no
    buttonAbortTitle       : 'CANCEL'
    buttonAbortClassName   : 'Button--secondary'
    buttonConfirmTitle     : 'OK'
    buttonConfirmClassName : 'Button--danger'
    buttonExtraTitle       : null
    buttonExtraClassName   : 'Button--primary'


  renderExtraButton: ->

    return null  unless @props.buttonExtraTitle

    <Modal.Button className={@props.buttonExtraClassName} onClick={@props.onButtonExtraClick}>
      {@props.buttonExtraTitle}
    </Modal.Button>


  render: ->
    <Modal {...@props}>
      <Modal.Title>{@props.title}</Modal.Title>
      <Modal.Content>
        {@props.children}
      </Modal.Content>
      <Modal.ButtonGroup>
        <Modal.Button className={@props.buttonConfirmClassName} onClick={@props.onConfirm}>
          {@props.buttonConfirmTitle}
        </Modal.Button>
        {@renderExtraButton()}
        <Modal.Button className={@props.buttonAbortClassName} onClick={@props.onAbort}>
          {@props.buttonAbortTitle}
        </Modal.Button>
      </Modal.ButtonGroup>
    </Modal>


