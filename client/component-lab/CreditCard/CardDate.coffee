React = require 'react'
Label = require 'lab/Text/Label'

module.exports = CardDate = ({ month, year, size, type }) ->

  year = String year

  <Label size={size} type={type}>
    {month}/{year.substr year.length - 2}
  </Label>


CardDate.defaultProps =
  size: 'small'
  type: 'secondary'
