#to-do Inject this method with KD.extend!
do ->

  # to-do log to mixpanel after subscription is upgraded
  KD.track = (rest...)->
    logToGoogle rest...

  logToGoogle = (rest...)->
    category = rest[0]
    action  =  rest[1]
    # there is nothing to do with the value now
    # value = rest[2]

    trackArray = ['_trackEvent', category, action]
    # log to google analytic
    _gaq.push(trackArray);
