_ = require 'lodash'
{ PropTypes } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

KeyboardKeys = require 'app/constants/keyboardKeys'

Input = require 'lab/Input/Input'
CreditCardInput = require 'lab/Input/CreditCardInput'
CreditCard = require 'lab/CreditCard'

styles = require './CreateCreditCardForm.stylus'

module.exports = CreateCreditCardForm = (props) ->

  { isDirty, handleSubmit, formValues: values, placeholders, loading, onEnter } = props


  if isDirty
    brand = values.brand
    cardProps = values
  else
    brand = placeholders.brand
    cardProps = placeholders

  onKeyDown = (event) ->
    if event.which is KeyboardKeys.ENTER
      onEnter()


  <form className={styles.main} onSubmit={handleSubmit} onKeyDown={onKeyDown}>
    <Row bottom='xs' between='xs'>
      <Col xs className={styles.mainCol}>
        <Row>
          <Col xs={12}>
            <CreditCardInput.Field
              disabled={loading}
              fieldType='number'
              name='number'
              placeholder={if isDirty then null else placeholders.number}
              brand={brand}
              title='Credit Card Number' />
          </Col>
        </Row>
        <Row bottom='xs' between='xs'>
          <Col xs={4} className={styles.tight}>
            <Input.Field
              mask={[/\d/, /\d/]}
              guide={off}
              name='exp_month'
              title='Expiration'
              placeholder={if isDirty then 'MM' else placeholders.exp_month} />
          </Col>
          <Col xs={4} className={styles.tight}>
            <Input.Field
              mask={[/\d/, /\d/, /\d/, /\d/]}
              guide={off}
              disabled={loading}
              name='exp_year'
              placeholder={if isDirty then 'YYYY' else placeholders.exp_year} />
          </Col>
          <Col xs={4} className={styles.tight}>
            <CreditCardInput.Field
              disabled={loading}
              key={brand}
              name='cvc'
              brand={brand}
              fieldType='cvc'
              title='CVC' />
          </Col>
        </Row>
      </Col>
      <Col xs className={styles.mainCol}>
        <Row bottom='xs'>
          <Col xs={12}>
            <CreditCard {...cardProps} />
          </Col>
        </Row>
      </Col>
    </Row>
  </form>
