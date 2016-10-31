_ = require 'lodash'
{ PropTypes } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

Input = require 'lab/Input/Input'
CreditCardInput = require 'lab/Input/CreditCardInput'
CreditCard = require 'lab/CreditCard'

styles = require './CreateCreditCardForm.stylus'

module.exports = CreateCreditCardForm = (props) ->

  { formValues, initialValues, handleSubmit, isDirty, loading } = props

  values = formValues or initialValues

  { brand } = values

  brand or= 'visa'

  <form className={styles.main} onSubmit={handleSubmit}>
    <Row bottom='xs' between='xs'>
      <Col xs className={styles.mainCol}>
        <Row>
          <Col xs={12}>
            <CreditCardInput.Field
              disabled={loading}
              fieldType='number'
              name='number'
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
              placeholder='MM' />
          </Col>
          <Col xs={4} className={styles.tight}>
            <Input.Field
              mask={[/\d/, /\d/, /\d/, /\d/]}
              guide={off}
              disabled={loading}
              name='exp_year'
              placeholder='YYYY' />
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
            <CreditCard {...values} brand={brand} />
          </Col>
        </Row>
      </Col>
    </Row>
  </form>


