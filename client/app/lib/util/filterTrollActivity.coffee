whoami = require './whoami'
checkFlag = require './checkFlag'

# filterTrollActivity filters troll activities from users.
# Only super-admins and other trolls can see these activities
module.exports = (account) ->
  return no unless account.isExempt
  return account._id isnt whoami()._id and not checkFlag 'super-admin'
