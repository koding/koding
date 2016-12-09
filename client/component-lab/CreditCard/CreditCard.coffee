{ PropTypes } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'
generateClassName = require 'classnames'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'

styles = require './CreditCard.stylus'
textStyles = require '../Text/Text.stylus'

{ Brand, Placeholder, NumberPattern } = require './constants'
helpers = require './helpers'

ensureProps = (props) ->
  return {
    name: props.name or Placeholder.NAME
    exp_month: props.exp_month or Placeholder.EXP_MONTH
    exp_year: props.exp_year or Placeholder.EXP_YEAR
    brand: props.brand or Brand.DEFAULT
    number: props.number or ''
  }

module.exports = CreditCard = (props) ->

  { brand, number, name, exp_year, exp_month } = ensureProps props

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
  name: Placeholder.NAME
  number: ''
  exp_month: Placeholder.EXP_MONTH
  exp_year: Placeholder.EXP_YEAR
  brand: Brand.DEFAULT


CreditCard.propTypes =
  name: PropTypes.string
  number: PropTypes.string
  brand: PropTypes.oneOf [
    Brand.JCB
    Brand.MAESTRO
    Brand.MASTER_CARD
    Brand.AMERICAN_EXPRESS
    Brand.DINERS_CLUB
    Brand.DISCOVER
    Brand.VISA
    Brand.DEFAULT
  ]


CardIcon = ({ brand }) -> <div className={styles["brand-#{brand}"]} />


CardChip = -> <div className={styles.chip} />


CardNumber = ({ number, brand, reverse }) ->

  blocks = helpers.getNumberBlocks number, brand

  children = blocks.map (block, index) ->
    <Label key={index} monospaced size='medium' type='secondary'>{block}</Label>

  <div className={styles.number}>{children}</div>


CardName = ({ name }) ->
  <Label monospaced size='small' type='secondary'>{name}</Label>


CardDate = ({ month, year }) ->
  year = String year
  <Label size='small' type='secondary'>
    {month}/{year.substr year.length - 2}
  </Label>


