{ PropTypes } = React = require 'react'

Button = require 'lab/Button'
Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'
{ Row, Col } = require 'react-flexbox-grid'

module.exports = ConfirmModal = (props) ->

  { title, message, isOpen, onCancel
    onConfirm, cancelTitle, confirmTitle } = props

  <Modal width="medium" height="short" showAlien={yes} isOpen={isOpen} contentLabel=''>
    <Modal.Header title={title} />
    <Modal.Content>
      <p><Label size="medium" type="info">{message}</Label></p>
    </Modal.Content>
    <Modal.Footer
      primaryButtonTitle={confirmTitle}
      onPrimaryButtonClick={onConfirm}
      secondaryButtonTitle={cancelTitle}
      onSecondaryButtonClick={onCancel} />
  </Modal>


ConfirmModal.propTypes =
  title: PropTypes.string.isRequired
  message: PropTypes.string.isRequired
  onConfirm: PropTypes.func.isRequired
  onCancel: PropTypes.func.isRequired
  cancelTitle: PropTypes.string.isRequired
  confirmTitle: PropTypes.string.isRequired
  isOpen: PropTypes.bool.isRequired
