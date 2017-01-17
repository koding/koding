DOT = '•'

Placeholder =
  NAME: '••••• •••••'
  EXP_MONTH: 'MM'
  EXP_YEAR: 'YY'
  NUMBER: '•••• •••• •••• ••••'
  CVC: '•••'
  NUMBER_AMERICAN_EXPRESS: '•••• •••••• •••••'
  CVC_AMERICAN_EXPRESS: '••••'

NumberPattern =
  DEFAULT: [4, 4, 4, 4]
  AMERICAN_EXPRESS: [4, 6, 5]

Brand =
  JCB: 'jcb'
  MAESTRO: 'maestro'
  MASTER_CARD: 'master-card'
  MASTERCARD: 'mastercard'
  AMERICAN_EXPRESS: 'american-express'
  DINERS_CLUB: 'diners-club'
  DISCOVER: 'discover'
  VISA: 'visa'
  DEFAULT: 'default'


module.exports = {
  Placeholder, NumberPattern, Brand, DOT
}
