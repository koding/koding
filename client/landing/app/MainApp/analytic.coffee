# to-do log to mixpanel after subscription is upgraded
KD.track = (rest...)->
  logToGoogle rest...
  logToMixpanel rest...

logToGoogle = (rest...)->
  category = rest.first
  action  =  rest.first
  # there is nothing to do with the value now
  # value = rest[2]

  trackArray = ['_trackEvent', category, action]
  # log to google analytic
  _gaq.push(trackArray);

logToMixpanel = (rest...)->
  if rest.first is "Connected to backend"
    # identify user on mixpanel
    kdMixpanel.registerUser()
    # create event for "userLoggedIn"

  if rest.first is "userSignedUp"
    #only for signup process
    kdMixpanel.track "$signup", KD.whoami().profile
  
  if rest.first is "userOpenedAce"
    group = rest[1]
    options =
      title     : group.title
      privacy   : group.privacy
      visibility: group.visibility
      $user     : KD.nick()
    # set first opening
    kdMixpanel.setOnce 'First Time Ace Opened', Date.now()
    # track ace openings
    kdMixpanel.track "Ace Opened", options


  if rest.first is "userOpenedTerminal"
    group = rest[1]
    options =
      $group     : group.title
      privacy   : group.privacy
      visibility: group.visibility
      $user     : KD.nick()
    # set first opening
    kdMixpanel.setOnce 'First Time Terminal Opened', Date.now()
    # track ace openings
    kdMixpanel.track "Terminal Opened", options

  if rest.first is "Apps" and rest[1] is "Install"
    options = 
      $user       : KD.nick()
      title       : rest[2]
      error       : rest[3]?
    kdMixpanel.track "Application Installed", options

  
  if rest.first is "User Clicked Buy VM"
    options = 
      $user       : KD.nick()
    kdMixpanel.track rest.first, options
  
  if rest.first is "Read Tutorial Book"
    # create event for "userReadTutorialBook"
    options = 
      $user       : KD.nick()
    kdMixpanel.track rest.first, options

  if rest.first is "Activity"
    group = KD.getSingleton('groupsController').getCurrentGroup()
    # create event for "userPostActivity"
    eventName = "User Post Activity"
    activity = "Status Update"
    switch rest[1]
      when "StatusUpdateSubmitted" then activity = "Status Update"
      when "BlogPostSubmitted" then activity = "Blog Post"
      when "TutorialSubmitted" then activity = "Tutorial Submitted"
      when "CodeShareSubmitted" then activity = "Code Shared"
      when "DiscussionSubmitted" then activity = "Discussion Started"
      else activity is rest[1]

    options =
      $group        : group.title
      privacy       : group.privacy
      visibility    : group.visibility
      $user         : KD.nick()
      $activity      : activity
    
    kdMixpanel.track eventName, options

  

  if rest[1] is "GroupJoinRequest"
    group           = rest[3]
    options         =
      $user         : KD.nick()
      $group        : group.title
      privacy       : group.privacy
      visibility    : group.visibility
    
    kdMixpanel.track "Group Join Request", options

  
  if rest[1] is "InvitationSentToFriend"
    options =
      $user       : KD.nick()
      $recipient  : rest[2]

    kdMixpanel.track "Invitation Send", options

###

  if rest.first is "trackpage"
    # mixpanel.track_page


  if rest.first is "userDevelopmentActivity"
    # create event for "userDevelopmentActivity"
    # add extra parameter for what has done
      # create new file
      # clone repository
      # created app
      # published app
###

