errorTypes = require('./error_types')

AuthenticationError = ->
  {
    message: 'Authentication Error',
    type: errorTypes.authenticationError
  }

AuthorizationError = ->
  {
    message: 'Authorization Error',
    type: errorTypes.authorizationError
  }

DownForMaintenanceError = ->
  {
    message: 'Down for Maintenance',
    type: errorTypes.downForMaintenanceError
  }

InvalidTransparentRedirectHashError = ->
  {
    message: 'The transparent redirect hash is invalid.',
    type: errorTypes.invalidTransparentRedirectHashError
  }

NotFoundError = ->
  {
    message: 'Not Found',
    type: errorTypes.notFoundError
  }

ServerError = ->
  {
    message: 'Server Error',
    type: errorTypes.serverError
  }

UnexpectedError = (message) ->
  {
    message: message,
    type: errorTypes.unexpectedError
  }

UpgradeRequired = ->
  {
    message: 'This version of the node library is no longer supported.',
    type: errorTypes.upgradeRequired
  }

exports.AuthenticationError = AuthenticationError
exports.AuthorizationError = AuthorizationError
exports.DownForMaintenanceError = DownForMaintenanceError
exports.InvalidTransparentRedirectHashError = InvalidTransparentRedirectHashError
exports.NotFoundError = NotFoundError
exports.ServerError = ServerError
exports.UnexpectedError = UnexpectedError
exports.UpgradeRequired = UpgradeRequired
