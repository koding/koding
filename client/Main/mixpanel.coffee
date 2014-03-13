# We decided to move to segment.io which multiplexes to many
# services. This is still named mixpanel for legacy reasons.
if KD.config.logToExternal then do ->
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    return  unless KD.isLoggedIn() and account and analytics

    account.fetchEmail (err, email)->
      console.log err  if err

      {type, meta, profile} = account
      {createdAt} = meta
      {firstName, lastName, nickname} = profile

      # register user to mixpanel
      analytics.identify nickname, {
        "$username"     : nickname
        "$first_name"   : firstName
        "$last_name"    : lastName
        "$email"        : email
        "$created"      : createdAt
        "Status"        : type
        "Randomizer"    : KD.utils.getRandomNumber 4
      }

# Access control wrapper around mixpanel object.
KD.mixpanel = (args...)->
  return  unless analytics and KD.config.logToExternal
  if args.length < 2
    args.push {}

  me = KD.whoami()
  return  unless me

  me.fetchEmail (err, email)->
    console.log err  if err

    args[1]["username"] = me.profile.nickname
    args[1]["email"] = email

    analytics.track args...

KD.mixpanel.alias = (args...)->
  return  unless analytics and KD.config.logToExternal
  analytics.alias args...
