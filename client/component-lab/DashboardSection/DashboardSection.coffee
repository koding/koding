React = require 'react'
generateClassName = require 'classnames'

Label = require 'lab/Text/Label'
Box = require 'lab/Box'
Message = require 'lab/Message'

styles = require './DashboardSection.stylus'

module.exports = DashboardSection = ({ title, children }) ->

  <div className={styles.main}>
    <div className={styles.title}>
      <Label size='small' type='info'>{title}</Label>
    </div>
    <Box border={1} type='default' className={styles.box}>
      {children}
    </Box>
  </div>

DashboardSection.Message = (props) ->
  <div className={styles.message}>
    <Message {...props} />
  </div>


DashboardSection.Footer = ({ children, border }) ->

  className = generateClassName [
    styles.footer
    border and styles.border
  ]

  <div className={className}>{children}</div>
