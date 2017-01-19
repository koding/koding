React = require 'react'

Button = require 'lab/Button'
Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'
{ Row, Col } = require 'react-flexbox-grid'

module.exports = CardRemoveConfirmModal = ({ isOpen, onCancel, onRemove }) ->

  title = "Are you sure?"
  message = "You are about to remove your credit card. Do you want to continue?"

  <Modal width="medium" height="short" showAlien={yes} isOpen={isOpen}>
    <Modal.Content>
      <div><Label size="large" type="danger">{title}</Label></div>
      <div>
        <p><Label size="small" type="info">{message}</Label></p>
      </div>
      <Row>
        <Col xs>
          <Button type="secondary" auto={on} onClick={onCancel}>CANCEL</Button>
        </Col>
        <Col xs>
          <Button type="primary-1" auto={on} onClick={onRemove}>REMOVE</Button>
        </Col>
      </Row>
    </Modal.Content>
  </Modal>
