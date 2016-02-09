
notifyAdmins = (group, name, data) ->

  group.fetchAdmins (err, admins = []) ->
    return console.error 'Failed to fetch admins:', err, group  if err
    admins.forEach (admin) ->
      admin.sendNotification name, data


notifyByUsernames = (usernames, name, data) ->
  JAccount = require './account'
  JAccount.some { 'profile.nickname': { $in: usernames } }, {}, (err, accounts = []) ->
    return console.error err  if err

    accounts.forEach (account) ->
      return  if err or not account

      account.sendNotification name, data

module.exports = {
  notifyAdmins
  notifyByUsernames
}
