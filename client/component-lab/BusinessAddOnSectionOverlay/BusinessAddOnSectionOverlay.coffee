React = require 'app/react'
styles = require './BusinessAddOnSectionOverlay.stylus'
Box = require 'lab/Box'
Button = require 'lab/Button'
Label = require 'lab/Text/Label'

module.exports = BusinessAddOnSectionOverlay = ({onClick}) ->

  <div className={styles.overlay}>
    <div className={styles.activationBox}>
      <Label>Requires Business Add-On</Label>
      <Button type="primary-1" size="medium" onClick={onClick}>ACTIVATE NOW</Button>
    </div>
  </div>