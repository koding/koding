React = require 'react'
Label = require 'lab/Text/Label'
helpers = require './helpers'
styles = require './CreditCard.stylus'

module.exports = CardNumber = ({ number, brand, size, type }) ->

  blocks = helpers.getNumberBlocks number, brand

  children = blocks.map (block, index) ->
    <Label
      key={index}
      monospaced
      size={size}
      type={type}
      children={block} />

  <div className={styles.number}>{children}</div>


CardNumber.defaultProps =
  size: 'medium'
  type: 'secondary'
