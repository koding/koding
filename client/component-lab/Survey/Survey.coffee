React = require 'react'
Box = require 'lab/Box'
Button = require 'lab/Button'
Label = require 'lab/Text/Label'
{ Grid, Row, Col } = require 'react-flexbox-grid'

styles = require './Survey.stylus'

noop = ->

module.exports = class Survey extends React.Component

  @propTypes =
    className: React.PropTypes.string
    onClick: React.PropTypes.func

  @defaultProps =
    className: ''
    onClick: noop

  render: ->

    <Box content={off} type="success">
      <div className={styles.container}>
        <div className={styles.left}>
          <img src="http://placehold.it/100x100" />
        </div>
        <div className={styles.middle}>
          <Box type="transparent">
            <div>
              <Label size="medium">Get $100 Free Credit Now!</Label>
            </div>
            <div>
              <Label size="small" type="info">
                Answer a few questions about your team and we will give
                you $100 Free credit.
              </Label>
            </div>
          </Box>
        </div>
        <div className={styles.right}>
          <Button type="primary-2" size="small" onClick={@props.onClick}>TAKE SURVEY</Button>
        </div>
      </div>
    </Box>
