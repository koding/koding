React = require 'react'
Label = require 'lab/Text/Label'
helpers = require './helpers'
styles = require './CreditCard.stylus'

{ Grid, Row, Col } = require 'react-flexbox-grid'

CardNumber = require './CardNumber'
CardIcon = require './CardIcon'
CardDate = require './CardDate'

module.exports = CardInfo = ({ number, brand, month, year, onToggleForm, formVisible }) ->

  buttonTitle = if formVisible then 'Cancel' else 'Change Card'

  <div className='CardInfo'>
    <Row className={styles['info-row']}>
      <Col xs={7}>
        <div className={styles.title}>Credit Card Number</div>
      </Col>
      <Col xs={5}>
        <div className={styles.title}>Expiration</div>
      </Col>
    </Row>
    <Row className={styles['info-row']}>
      <Col style={padding: '0 .5rem'}>
        <CardIcon
          size='small'
          brand={brand}
          style={background: '#989898'} />
      </Col>

      <Col xs={5}>
        <CardNumber
          size={18}
          type='default'
          number={number}
          brand={brand} />
      </Col>

      <Col xs />

      <Col xs={2}>
        <CardDate
          size={18}
          type='default'
          month={month}
          year={year} />
      </Col>

      <Col xs={3} style={textAlign: 'right'}>
        <a href='#' className={styles.link} onClick={onToggleForm}>
          {buttonTitle}
        </a>
      </Col>
    </Row>
  </div>
