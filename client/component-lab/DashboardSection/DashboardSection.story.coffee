React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
{ Grid, Row, Col } = require 'react-flexbox-grid'

DashboardSection = require './DashboardSection'
CreateCreditCardForm = require 'lab/CreateCreditCardForm'
Button = require 'lab/Button'

storiesOf 'DashboardSection', module
  .add 'default', ->
    <div style={{background:'#F5F3F3', width: '650px', padding: '30px'}}>
      <DashboardSection title='Payment Information'>
        <DashboardMessage />
        <CreateCreditCardForm />
        <DashboardFooter />
      </DashboardSection>
    </div>


DashboardFooter = ->

  <DashboardSection.Footer border>
    <Row style={{margin: '0'}} between='xs'>
      <Col>
        <Button size='small'>SAVE</Button>
        <Button size='small' type='link-secondary'>REMOVE CARD</Button>
      </Col>
      <Col>
        <Button size='small' type='link-primary-6'>PAYMENT HISTORY</Button>
      </Col>
    </Row>
  </DashboardSection.Footer>


DashboardMessage = ->

  description = '
    We were unable to verify your card. Please check the details you entered
    below and try again.
  '

  IconComponent = ->
    one = require 'app/sprites/1x/cc-error.png'
    two = require 'app/sprites/2x/cc-error.png'

    imgOne = new Image
    imgOne.src = one
    { naturalHeight: height, naturalWidth: width } = imgOne

    src = if global.devicePixelRatio >= 2 then two else one

    <span><img src={src} style={{height, width}} /></span>

  <DashboardSection.Message
    IconComponent={IconComponent}
    type='danger'
    title='Credit Card Error'
    description={description} />
