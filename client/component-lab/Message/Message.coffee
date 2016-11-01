{ PropTypes } = React = require 'react'
{ Row, Col } = require 'react-flexbox-grid'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'
Button = require 'lab/Button'

styles = require './Message.stylus'

module.exports = Message = (props) ->

  { title, description, type
    buttonTitle, onButtonClick
    IconComponent, onCloseClick } = props

  <Box radius={no} type={type} className={styles.main}>
    {onCloseClick and
      <CloseIcon onClick={onCloseClick} />
    }
    <Row center="xs" middle="xs">
      {IconComponent and
        <Col className={styles.icon}>
          <IconComponent />
        </Col>
      }
      <Col xs>
        <Row start="xs">
          <Col xs={12} className={styles.title}>
            <Label type='small' type={type}>
              <strong>{title}</strong>
            </Label>
          </Col>
        </Row>
        <Row start='xs'>
          <Col xs={12} className={styles.description}>
            <Label size='xsmall' type='info'>
              {description}
            </Label>
          </Col>
        </Row>
      </Col>
      {buttonTitle and
        <Col className={styles.button}>
          <Button size='small' onClick={onButtonClick}>
            {buttonTitle}
          </Button>
        </Col>
      }
    </Row>
  </Box>

Message.defaultProps =
  onCloseClick: noop
  onButtonClick: noop


CloseIcon = ({ onClick }) ->
  <div onClick={onClick} className={styles.close}>
    <figure />
  </div>

noop = ->
