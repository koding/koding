{ PropTypes } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

Input = require 'lab/Input/Input'
CreditCardInput = require 'lab/Input/CreditCardInput'
CreditCard = require 'lab/CreditCard'

styles = require './CreateCreditCardForm.stylus'

module.exports = CreateCreditCardForm = (props) ->

  { values, handleSubmit } = props
  { brand } = values

  <form className={styles.main} onSubmit={handleSubmit}>
    <Row bottom='xs' between='xs'>
      <Col xs className={styles.mainCol}>
        <Row>
          <Col xs={12}>
            <CreditCardInput.Field
              fieldType='number'
              name='number'
              brand={brand}
              title='Credit Card Number' />
          </Col>
        </Row>
        <Row bottom='xs' between='xs'>
          <Col xs={4} className={styles.tight}>
            <Input.Field
              name='exp_month'
              title='Expiration'
              placeholder='Month' />
          </Col>
          <Col xs={4} className={styles.tight}>
            <Input.Field
              name='exp_year'
              placeholder='Year' />
          </Col>
          <Col xs={4} className={styles.tight}>
            <CreditCardInput.Field
              key={brand}
              name='cvc'
              brand={brand}
              fieldType='cvc'
              title='CVC' />
          </Col>
        </Row>
        <Row>
          <Col xs={12}>
            <Input.Field
              name='name'
              placeholder='Enter your name and surname…'
              title='Full Name' />
          </Col>
        </Row>
      </Col>
      <Col xs className={styles.mainCol}>
        <Row bottom='xs'>
          <Col xs={12}>
            <CreditCard brand={brand} {...values} />
          </Col>
        </Row>
        <Row bottom='xs'>
          <Col xs={12}>
            <Input.Field
              name='email'
              placeholder='Enter billing email…'
              title='Billing Email Adress' />
            </Col>
        </Row>
      </Col>
    </Row>
  </form>


