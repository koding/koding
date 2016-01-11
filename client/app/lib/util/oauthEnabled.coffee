# Chrome apps open links in a new browser window. OAuth authentication
#   # relies on `window.opener` to be present to communicate back to the
#     # parent window, which isn't available in a chrome app. Therefore, we
#       # disable/change oauth behavior based on this flag: SA.

module.exports = ->
  global.name isnt "chromeapp"
