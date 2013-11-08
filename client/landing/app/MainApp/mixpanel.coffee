class KDMixpanel

  createEvent:(rest...) =>
    eventName = rest.first
    eventData = rest[1]
    $user   = KD.nick()

    if eventName is "Login" or (eventName is "Groups" and eventData is "ChangeGroup")
      # identify user on mixpanel
      #@registerUser()
    else if eventName is "Connected to backend"
      @track eventName, KD.nick()
      #@registerUser()
    else if eventName is "New User Signed Up"
      @track eventName, KD.whoami().profile
    else if eventName is "User Opened Ace"
      {title, privacy, visibility} = eventData

      options = {title, privacy, visibility, $user}
      @setOnce 'First Time Ace Opened', Date.now()
      @track eventName, options

    else if eventName is "userOpenedTerminal"
      {title, privacy, visibility} = eventData
      options = {title, privacy, visibility, $user}
      @setOnce 'First Time Terminal Opened', Date.now()
      @track "User Opened Terminal", options

    else if eventName is "Apps" and eventData is "Install"

      appTitle   = rest[2]
      options    = {$user, appTitle}
      @track "Application Installed", options

    else if eventName is "User Clicked Buy VM"
      @track eventName, $user

    else if eventName is "Read Tutorial Book"
      @track eventName, $user

    else if eventName is "Activity"
      eventName = "User Post Activity"
      activity  = "Status Updated"
      switch eventData
        when "StatusUpdateSubmitted" then activity = "Status Updated"
        when "BlogPostSubmitted"     then activity = "Blog Post"
        when "TutorialSubmitted"     then activity = "Tutorial Submitted"
        when "DiscussionSubmitted"   then activity = "Discussion Started"
        else activity is eventData

      group     = KD.getSingleton('groupsController').getCurrentGroup()
      $activity = activity

      {title, privacy, visibility} = group
      options = {title, privacy, visibility, $user, $activity}

      @track eventName, options

    else if eventName is "Groups" and eventData is "JoinedGroup"
      @track "User Joined Group", {group:rest[2]}
    else if eventName is "Groups" and eventData is "CreateNewGroup"
      @track "User Created Group", {group:rest[2]}
    else if eventName is "Members" and eventData is "OwnProfileView"
      @track "User Viewed Self Profile", {$username:rest[2]}
    else if eventName is "Members" and eventData is "ProfileView"
      @track "User Viewed Profile", {$username:rest[2]}
    else if eventName is "Apps" and eventData is "ApplicationDelete"
      @track "User Deleted Application", {$username:rest[2]}
    else
      if eventData is "GroupJoinRequest"
        group = rest[3]
        {title, privacy, visibility} = group
        options = {title, privacy, visibility, $user}
        @track "Group Join Request", options

      else if eventData is "InvitationSentToFriend"
        options       =
          $user       : $user
          $recipient  : rest[2]

        @track "Invitation Send", options
      else
        log "Warning: Unknown mixpanel event set", rest

  track:(eventName, properties, callback)->
    mixpanel.track eventName, properties, callback

  trackPageView:(pageURL)->
    mixpanel.track_pageview pageURL

  getProperty:(name)->
    mixpanel.get_property name

  incrementUserProperty:(property, incrementBy=1)->
    mixpanel.people.increment property, incrementBy

  #identifies user on mixpanel, by default username on koding, should be unique
  registerUser:->
    if KD.isLoggedIn()
      user  = KD.whoami()
      email = user.fetchEmail (err, email)->
        mixpanel.identify user.profile.nickname
        mixpanel.people.set
          "$username"   : user.profile.nickname
          "name"        : "#{user.profile.firstName} #{user.profile.lastName}"
          "$joinDate"   : user.meta.createdAt
          "$email"      : email
        mixpanel.name_tag "#{user.profile.nickname}.kd.io"

  setOnce:(property, value, callback )->
    mixpanel.people.set_once property, value, callback

if mixpanel and KD.config.logToExternal then do ->
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    if KD.isLoggedIn()
      user       = KD.whoami()
      {nickname} = user.profile
      email      = user.fetchEmail (err, email)->
        {firstName, lastName} = user.profile
        {createdAt}           = user.meta

        # register user to mixpanel
        mixpanel.identify nickname
        mixpanel.people.set
          "$username"   : nickname
          "name"        : "#{firstName} #{lastName}"
          "$joinDate"   : createdAt
          "$email"      : email
        mixpanel.name_tag "#{nickname}.kd.io"
