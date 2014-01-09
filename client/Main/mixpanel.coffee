if KD.config.logToExternal then do ->
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    return  unless KD.isLoggedIn()
    return  unless account

    account.fetchEmail (err, email)->
      console.log err  if err

      {type, meta, profile} = account
      {createdAt} = meta
      {firstName, lastName, nickname} = profile

      # register user to mixpanel
      mixpanel?.identify nickname
      mixpanel?.people.set
        "$username"     : nickname
        "$first_name"   : firstName
        "$last_name"    : lastName
        "$email"        : email
        "$created"      : createdAt
        "Status"        : type
        "Randomizer"    : KD.utils.getRandomNumber 4
      mixpanel?.name_tag "#{nickname}.kd.io"

# Access control wrapper around mixpanel object.
KD.mixpanel = (args...)->
  mixpanel?.track args...  if KD.config.logToExternal

KD.mixpanel.alias = (args...)-> mixpanel?.alias args...
