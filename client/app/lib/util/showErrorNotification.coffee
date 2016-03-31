kd = require 'kd'
showNotification = require './showNotification'

# TODO after error message handling method is decided replace this function
# with showError
module.exports = (err, options = {}) ->
  { message, name } = err  if err

  switch name
    when 'AccessDenied'
      options.fn = kd.warn
      options.type = 'growl'
      message = options.userMessage
    else
      options.userMessage = 'Error, please try again later!'
      options.fn = kd.error

  showNotification message, options
