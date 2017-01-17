React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Modal = require './Modal'
Label = require 'lab/Text/Label'
{ Row, Col } = require 'react-flexbox-grid'

class ModalContainer extends React.Component
  constructor: (props) ->
    super props
    @state = { isOpen: yes }

  onClick: ->
    @setState isOpen: !@state.isOpen

  render: ->
    <div>
      <Button onClick={@onClick.bind this}>Open Modal</Button>
      {React.Children.map @props.children, (Component) =>
        React.cloneElement Component, { isOpen: @state.isOpen, onRequestClose: @onClick.bind this } }
    </div>


storiesOf 'Modal', module
  .add 'header & footer', ->
    <ModalContainer>
      <Modal showAlien={yes}>
        <Modal.Header title="Credential Preview" />
        <Modal.Content />
        <Modal.Footer />
      </Modal>
    </ModalContainer>
  .add 'small only content', ->
    <ModalContainer>
      <Modal width="medium" height="short" showAlien={yes}>
        <Modal.Content>
          <div><Label size="large" type="danger">Are you sure?</Label></div>
          <div>
            <p>
              <Label size="small" type="info">
              You are about to remove your credit card. Do you want to continue?
              </Label>
            </p>
          </div>
          <Row>
            <Col xs><Button type="secondary" auto={on} onClick={action 'OK, GOT IT'}>CANCEL</Button></Col>
            <Col xs><Button type="primary-1" auto={on} onClick={action 'OK, GOT IT'}>REMOVE</Button></Col>
          </Row>
        </Modal.Content>
      </Modal>
    </ModalContainer>
