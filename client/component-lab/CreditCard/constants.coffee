Placeholder =
  NUMBER: '•••• •••• •••• ••••'
  EXP_MONTH: 'MM'
  EXP_YEAR: 'YY'
  CVC: '•••'
  NUMBER_AMEX: '•••• •••••• •••••'
  CVC_AMEX: '••••'
  NAME: '••••• •••••'

NumberPattern =
  DEFAULT: [4, 4, 4, 4]
  AMEX: [4, 6, 5]

Brand =
  JCB: 'jcb'
  MAESTRO: 'maestro'
  MASTER_CARD: 'master-card'
  AMERICAN_EXPRESS: 'american-express'
  DINERS_CLUB: 'diners-club'
  DISCOVER: 'discover'
  VISA: 'visa'
  DEFAULT: 'default'

DOT = '•'

module.exports = {
  Placeholder, NumberPattern, Brand, DOT
}

