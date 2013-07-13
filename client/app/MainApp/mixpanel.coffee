class KDMixpanel

  constructor:->
    @trackPageView "/Topics"
    @trackPageView "/Members"
    @trackPageView "/Groups"
    @trackPageView "/Develop"
    @trackPageView "/Develop/Ace"
    @trackPageView "/Develop/Terminal"
    @trackPageView "/Apps"
    @trackPageView "/Account"

    KD.getSingleton('mainController').on "AccountChanged", (account) =>
      if typeof account is 'JAccount'
        @registerUser()

  track:(eventName, properties,callback)=>
    mixpanel.track eventName,properties,(callback)

  trackPageView:(pageURL)=>
    mixpanel.track_pageview pageURL

  register:(options)=>
    mixpanel.register options

  registerOnce:(options, dafaultValue)=>
    mixpanel.register_once options, dafaultValue

  getProperty:(name)=>
    mixpanel.get_property name

  incrementUserProperty:(property, incrementBy=1)=>
    mixpanel.people.increment property, incrementBy

  #identifies user on mixpanel, by default username on koding, should be unique
  registerUser:=>
    user = KD.whoami()
    username = user.profile.nickname
    mixpanel.identify username
    mixpanel.people.set 
      "$username"   : username
      "name"        : "#{user.profile.firstName} #{user.profile.lastName}"
      "$joinDate"   : user.meta.createdAt

    mixpanel.name_tag "#{username}.kd.io"

  setOnce:(eventName, options, callback )=>
    mixpanel.people.set_once eventName, options, callback


  userReadManual:(page)=>
    @setOnce "Instructions Book",
      "Read Date"   : Date.now()
      "Pages"       : page

  userLoggedIn:(account)=>
    @track "UserLoggedIn" ,
      "$username"   : account.profile.nickname
      "$loginDate"  : Date.now()


  userRegistered:(account)=>
    @track "UserRegistered", 
      "$username"   : account.profile.nickname
      "$loginDate"  : Date.now()


KD.logToMixpanel = (args, percent=100)->
    if KD.utils.runXpercent percent
      mixpanel.track args
      log "Log #{percent}% of time: #{args}"

if mixpanel? && KD.config.logToExternal then do ->
  KD.mixpanel = new KDMixpanel
