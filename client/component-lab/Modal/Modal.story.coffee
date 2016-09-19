React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Modal = require './Modal'
Label = require 'lab/Text/Label'

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
          <div><Label size="large" type="success">Good News!</Label></div>
          <div>
            <Label size="medium" type="info">
              <strong>You have received $500 in free credit.</strong>
            </Label>
          </div>
          <div>
            <p>
              <Label size="small" type="info">
                Your free credit can be applied to payments for your entire team
                after you have verified your email address and entered your
                credit card.
              </Label>
            </p>
          </div>
          <Button type="primary-1" auto={on} onClick={action 'OK, GOT IT'}>OK, GOT IT</Button>
        </Modal.Content>
      </Modal>
    </ModalContainer>

