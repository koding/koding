KodingError = require '../../error'

KnownApiErrors =
  'koding.BadRequest' : 'BadRequest'

module.exports = class ApiError extends Error
  constructor:({ description, error }) ->
    name = KnownApiErrors[error] ? 'BadRequest'
    return new KodingError description, name
