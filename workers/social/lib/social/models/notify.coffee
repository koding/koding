JName = require './name'
JUser = require './user'


notifyByUsernames = (usernames, name, data) ->

  JName.fetchModels usernames, (err, results) ->

    return console.error err  if err

    users = (result.models[0]  for result in results \
      when result.models[0] instanceof JUser)

    users.forEach (user) ->
      user.fetchOwnAccount (err, account) ->
        return  if err or not account
        account.sendNotification name, data


module.exports = {
  notifyByUsernames
}
