React = require 'react'
styles = require './CreditCard.stylus'
classnames = require 'classnames'

{ Brand } = require './constants'
Icon = require 'lab/Icon'

ICONS_BIG =
  'american-express':
    '1x': require './assets/1x/amex-big.png'
    '2x': require './assets/2x/amex-big.png'
  'diners-club':
    '1x': require './assets/1x/dinersclub-big.png'
    '2x': require './assets/2x/dinersclub-big.png'
  discover:
    '1x': require './assets/1x/discover-big.png'
    '2x': require './assets/2x/discover-big.png'
  jcb:
    '1x': require './assets/1x/jcb-big.png'
    '2x': require './assets/2x/jcb-big.png'
  maestro:
    '1x': require './assets/1x/maestro-big.png'
    '2x': require './assets/2x/maestro-big.png'
  mastercard:
    '1x': require './assets/1x/mastercard-big.png'
    '2x': require './assets/2x/mastercard-big.png'
  visa:
    '1x': require './assets/1x/visa-big.png'
    '2x': require './assets/2x/visa-big.png'

ICONS_BIG['master-card'] = ICONS_BIG['mastercard']

ICONS_SMALL =
  'american-express':
    '1x': require './assets/1x/amex-small.png'
    '2x': require './assets/2x/amex-small.png'
  'diners-club':
    '1x': require './assets/1x/dinersclub-small.png'
    '2x': require './assets/2x/dinersclub-small.png'
  discover:
    '1x': require './assets/1x/discover-small.png'
    '2x': require './assets/2x/discover-small.png'
  jcb:
    '1x': require './assets/1x/jcb-small.png'
    '2x': require './assets/2x/jcb-small.png'
  maestro:
    '1x': require './assets/1x/maestro-small.png'
    '2x': require './assets/2x/maestro-small.png'
  mastercard:
    '1x': require './assets/1x/mastercard-small.png'
    '2x': require './assets/2x/mastercard-small.png'
  visa:
    '1x': require './assets/1x/visa-small.png'
    '2x': require './assets/2x/visa-small.png'

ICONS_SMALL['master-card'] = ICONS_SMALL['mastercard']

module.exports = CardIcon = ({ brand, small, style }) ->

  wrapperClassName = classnames [
    styles['brand-wrapper']
    small and styles['small']
  ]

  <div className={wrapperClassName} style={style}>
    <BrandImage brand={brand} small={small} />
  </div>


BrandImage = ({ brand, small }) ->

  if brand is Brand.DEFAULT
    className = classnames [
      styles['brand-default']
      small and styles['small']
    ]
    
    return (
      <span className={className} />
    )


  icons = if small then ICONS_SMALL[brand] else ICONS_BIG[brand]

  <Icon 1x={icons['1x']} 2x={icons['2x']} />

CardIcon.defaultProps =
  small: no
  brand: Brand.DEFAULT
