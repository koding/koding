React = require 'app/react'
cx = require 'classnames'

Popover = require 'app/components/common/popover'

module.exports = SidebarWidget = (props) ->

  { className, children } = props

  <Popover
    {...props}
    className={cx 'SidebarWidget', className}
    children={children}
  />
