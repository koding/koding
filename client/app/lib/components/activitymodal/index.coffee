kd     = require 'kd'
React  = require 'kd-react'
Modal  = require 'app/components/modal'

module.exports = class ActivityModal extends React.Component

  @defaultProps =
    onClose             : kd.noop
    closeOnEsc          : yes
    closeOnOutsideClick : yes
    hasOverlay          : yes
    isOpen              : no
    buttonAbortTitle    : 'CANCEL'


  render: ->
    <Modal {...@props}>
      <Modal.Title>{@props.title}</Modal.Title>
      <Modal.Content>
        {@props.children}
      </Modal.Content>
      <Modal.ButtonGroup>
        <Modal.Button className="Button--danger" onClick={@props.onConfirm}>
          {@props.buttonConfirmTitle}
        </Modal.Button>
        <Modal.Button className="Button--secondary" onClick={@props.onAbort}>
          {@props.buttonAbortTitle}
        </Modal.Button>
      </Modal.ButtonGroup>
    </Modal>


