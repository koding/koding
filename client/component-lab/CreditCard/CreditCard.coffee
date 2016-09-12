{ PropTypes } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'
generateClassName = require 'classnames'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'

styles = require './CreditCard.stylus'
textStyles = require '../Text/Text.stylus'

module.exports = CreditCard = (props) ->

  { brand, number, name, exp_year, exp_month } = props

  exp_month or= CreditCard.defaultProps.exp_month
  exp_year or= CreditCard.defaultProps.exp_year

  <Box className={styles.main}>
    <Row className={styles.header}>
      <Col xs={6}><CardIcon brand={brand} /></Col>
      <Col xs={6}><CardChip /></Col>
    </Row>
    <Row>
      <Col xs={12}>
        <CardNumber brand={brand} number={number} />
      </Col>
    </Row>
    <Row className={styles.footer}>
      <Col xs={8} className={styles.name}>
        <CardName name={name} />
      </Col>
      <Col xs={4} className={textStyles.right}>
        <CardDate month={exp_month} year={exp_year} />
      </Col>
    </Row>
  </Box>

CreditCard.defaultProps =
  brand: 'visa'
  number: ''
  exp_month: 'MM'
  exp_year: 'YY'
  name: 'A koding user'


CardIcon = ({ brand }) -> <div className={styles["brand-#{brand}"]} />


CardChip = -> <div className={styles.chip} />


CardNumber = ({ number, brand, reverse }) ->

  isAmex = brand is 'american-express'

  template = if isAmex then [4, 6, 5] else [4, 4, 4, 4]

  number = number.replace /\s/g, ''

  cursor = 0
  children = template.map (length, index) ->
    slice = number.substr cursor, length
    cursor += length

    diff = length - slice.length
    filler = [0...diff].map(-> '•').join('')
    slice = "#{slice}#{filler}"

    <Label key={index} monospaced size='medium' type='secondary'>{slice}</Label>

  <div className={styles.number}>{children}</div>


CardName = ({ name }) -> <Label size='small' type='secondary'>{name}</Label>


CardDate = ({ month, year }) ->
  year = String year
  <Label size='small' type='secondary'>
    {month}/{year.substr year.length - 2}
  </Label>


