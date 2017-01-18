kd = require 'kd'
{ PropTypes } = React = require 'react'
pluralize = require 'pluralize'
{ Row, Col } = require 'react-flexbox-grid'
formatNumber = require 'app/util/formatNumber'

textStyles = require 'lab/Text/Text.stylus'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'


TrialChargeInfo = ({ teamSize, pricePerSeat, daysLeft }) ->

  <Box border={1} type='secondary'>
    <Row>
      <Col xs={5}>
        <Label size="small">
          Team Size: <strong>{pluralize 'Developer', teamSize, yes}</strong>
        </Label>
      </Col>
      <Col xs={7} className={textStyles.right + ' hidden'}>
        <Label size="small">
          Monthly charge after trial:&nbsp;
          <strong>${formatNumber pricePerSeat, 2}</strong> per user
        </Label>
      </Col>
    </Row>
  </Box>


TrialChargeInfo.propTypes =
  teamSize: PropTypes.number
  pricePerSeat: PropTypes.number

TrialChargeInfo.defaultProps =
  teamSize: 1
  pricePerSeat: 49.977777777777776

module.exports = TrialChargeInfo
