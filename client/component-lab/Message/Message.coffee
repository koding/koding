{ PropTypes } = React = require 'react'
{ Row, Col } = require 'react-flexbox-grid'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'

styles = require './Message.stylus'

module.exports = Message = ({ title, description, type, IconComponent, onCloseClick }) ->

  <Box radius={no} type={type} className={styles.main}>
    <CloseIcon onClick={onCloseClick} />
    <Row>
      {<IconComponent />  if IconComponent}
      <Col xs>
        <Row>
          <Col xs={12}>
            <Label type={type}>
              <strong>{title}</strong>
            </Label>
          </Col>
          <Col xs={12}>
            <Label size='small' type='info'>
              {description}
            </Label>
          </Col>
        </Row>
      </Col>
    </Row>
  </Box>


CloseIcon = ({ onClick }) ->
  <div onClick={onClick} className={styles.close}>
    <figure />
  </div>
