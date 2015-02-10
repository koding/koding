# We decided to move to segment.io which multiplexes to many
# services. This is still named mixpanel for legacy reasons.
if KD.config.logToExternal then do ->
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    return  unless KD.isLoggedIn() and account and analytics

    {_id, meta, profile} = account
    return  unless profile

    KD.utils.defer ->
      KD.remote.api.JUser.fetchUser (err, user)->
        return  if err or not user

        {firstName, lastName, nickname} = profile
        {email, lastLoginDate, status, emailFrequency, foreignAuth, sshKeys} = user

        # only care about existence of 3rd party auth, not the values
        providers = {}
        if foreignAuth
          for own provider, providerInfo of foreignAuth
            # check if values isn't empty object
            providers[provider] = yes  if Object.keys(providerInfo).length > 0

        KD.singletons.paymentController.subscriptions (err, currentSub)->
          plan = "error fetching plan" if err
          args =
            "$id"          : _id
            "$username"    : nickname
            "$first_name"  : firstName
            "$last_name"   : lastName
            "$created"     : meta?.createdAt
            "$email"       : email
            subscription   : currentSub
            lastLoginDate  : lastLoginDate
            status         : status
            emailFrequency :
              marketing    : emailFrequency?.marketing
              global       : emailFrequency?.global
            foreignAuth    : providers      if Object.keys(providers).length > 0
            sshKeysCount   : sshKeys.length if sshKeys?.length > 0

          analytics.identify nickname, args

# Access control wrapper around mixpanel object.
KD.mixpanel = (args...)->
  return  unless analytics and KD.config.logToExternal
  if args.length < 2
    args.push {}

  me = KD.whoami()
  return  unless me.profile

  KD.gaEvent args[0]

  args[1]["username"] = me.profile.nickname

  analytics.track args...

KD.mixpanel.alias = (args...)->
  return  unless analytics and KD.config.logToExternal
  analytics.alias args...
