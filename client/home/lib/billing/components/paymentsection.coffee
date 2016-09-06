React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Button = require 'lab/Button'
CreateCreditCardForm = require './creditcardcontainer'

module.exports = class PaymentSection extends React.Component

  onSubmit: -> @_form.submit()

  render: ->

    { message, onMessageClose } = @props

    <DashboardSection title='Payment Information'>
      {<PaymentSectionMessage {...message} onCloseClick={onMessageClose} />  if message}
      <CreateCreditCardForm ref={(f) => @_form = f} />
      <Footer border>
        <Row style={{margin: '0'}} between='xs'>
          <Col>
            <Button size='small' onClick={@onSubmit.bind this}>SAVE</Button>
            <Button size='small' type='link-secondary'>REMOVE CARD</Button>
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

  imgOne = new Image
  imgOne.src = one
  { naturalHeight: height, naturalWidth: width } = imgOne

  src = if global.devicePixelRatio >= 2 then two else one

  <span><img src={src} style={{height, width}} /></span>


SuccessIcon = ->

  one = require 'app/sprites/1x/cc-error.png'
  two = require 'app/sprites/2x/cc-error.png'

  imgOne = new Image
  imgOne.src = one
  { naturalHeight: height, naturalWidth: width } = imgOne

  src = if global.devicePixelRatio >= 2 then two else one

  <span><img src={src} style={{height, width}} /></span>
