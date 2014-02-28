if KD.config.logToExternal then do ->
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    return  unless KD.isLoggedIn() and account and mixpanel

    account.fetchEmail (err, email)->
      console.log err  if err

      {type, meta, profile} = account
      {createdAt} = meta
      {firstName, lastName, nickname} = profile

      # register user to mixpanel
      mixpanel.identify nickname
      mixpanel.people.set
        "$username"     : nickname
        "$first_name"   : firstName
        "$last_name"    : lastName
        "$email"        : email
        "$created"      : createdAt
        "Status"        : type
        "Randomizer"    : KD.utils.getRandomNumber 4
      mixpanel.name_tag "#{nickname}.kd.io"

# Access control wrapper around mixpanel object.
KD.mixpanel = (args...)->
  return  unless mixpanel and KD.config.logToExternal
  if args.length < 2
    args.push {}

  me = KD.whoami()
  me.fetchEmail (err, email)->
    console.log err  if err

    args[1]["username"] = me.profile.nickname
    args[1]["email"] = email

    mixpanel.track args...

KD.mixpanel.alias = (args...)->
  return  unless mixpanel and KD.config.logToExternal
  mixpanel.alias args...
