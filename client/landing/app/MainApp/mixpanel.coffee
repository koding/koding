class KDMixpanel
  
  track:(eventName, properties, callback)->
    mixpanel.track eventName, properties, (callback)

  trackPageView:(pageURL)->
    mixpanel.track_pageview pageURL

  register:(options)->
    mixpanel.register options

  registerOnce:(options, dafaultValue)->
    mixpanel.register_once options, dafaultValue

  getProperty:(name)->
    mixpanel.get_property name

  incrementUserProperty:(property, incrementBy=1)->
    mixpanel.people.increment property, incrementBy

  #identifies user on mixpanel, by default username on koding, should be unique
  registerUser:->
    user = KD.whoami()
    # coundnt get JGuest so looking from nick
    unless KD.nick() is "Guest"
      mixpanel.identify user.profile.firstName
      mixpanel.people.set
        "$username"   : user.profile.firstName
        "name"        : "#{user.profile.firstName} #{user.profile.lastName}"
        "$joinDate"   : user.meta.createdAt
      mixpanel.name_tag "#{user.profile.nickname}.kd.io"


  setOnce:(property, value, callback )->
    mixpanel.people.set_once property, value, callback


  userReadManual:(page)->
    @setOnce "Instructions Book",
      "Read Date"   : Date.now()
      "Pages"       : page

  userLoggedIn:(account)->
    @track "UserLoggedIn" ,
      "$username"   : account.profile.nickname
      "$loginDate"  : Date.now()


  userRegistered:(account)->
    @track "UserRegistered",
      "$username"   : account.profile.nickname
      "$loginDate"  : Date.now()

if KD.config.logToExternal then kdMixpanel = new KDMixpanel