React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Button = require 'lab/Button'
CreateCreditCardForm = require './creditcardcontainer'

Icon = require 'lab/Icon'

module.exports = class PaymentSection extends React.Component

  onSubmit: -> @_form.getWrappedInstance().submit()

  render: ->

    { message, onMessageClose, isDirty, hasCard, submitting, loading } = @props

    <DashboardSection title='Payment Information'>

      {message and
        <PaymentSectionMessage {...message} onCloseClick={onMessageClose} />}

      <CreateCreditCardForm loading={loading} ref={(f) => @_form = f} />

      <Footer border>
        <Row style={{margin: '0'}} between='xs'>
          <Col>
            <Button
              size='small'
              disabled={not isDirty or submitting}
              onClick={@onSubmit.bind this}>SAVE</Button>

            {hasCard and
              <Button size='small' type='link-secondary'>REMOVE CARD</Button>}
          </Col>
          <Col>
            <Button size='small' type='link-primary-6'>PAYMENT HISTORY</Button>
          </Col>
        </Row>
      </Footer>
    </DashboardSection>


PaymentSectionMessage = ({ type, title, description, onCloseClick }) ->

  IconComponent = if 'danger' is type then ErrorIcon else SuccessIcon

  <DashboardSection.Message
    onCloseClick={onCloseClick}
    IconComponent={IconComponent}
    type={type}
    title={title}
    description={description} />


ErrorIcon = ->

  one = require 'app/sprites/1x/cc-error.png'
  two = require 'app/sprites/2x/cc-error.png'

  <Icon 1x={one} 2x={two} />


SuccessIcon = ->

  one = require 'app/sprites/1x/cc-error.png'
  two = require 'app/sprites/2x/cc-error.png'

  <Icon 1x={one} 2x={two} />
