kd                     = require 'kd'
whoami                 = require 'app/util/whoami'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
globals                = require 'globals'

KODING_CHATLIO_KEY     = 'ae02da65-1664-4e7b-49c8-31abedbb80ed'

bootChatlio = (id, team) ->

  # this thing is js to coffee of chatlio embed code
  window._chatlio = window._chatlio or []
  !do ->
    t = document.getElementById('chatlio-widget-embed')
    if t and window.ChatlioReact and _chatlio.init
      return undefined

    e = (t) ->
      ->
        _chatlio.push [ t ].concat(arguments)
        return

    i = [
      'configure'
      'identify'
      'track'
      'show'
      'hide'
      'isShown'
      'isOnline'
    ]
    a = 0
    while a < i.length
      _chatlio[i[a]] or (_chatlio[i[a]] = e(i[a]))
      a++
    n = document.createElement('script')
    c = document.getElementsByTagName('script')[0]
    n.id = 'chatlio-widget-embed'
    n.src = 'https://w.chatlio.com/w.chatlio-widget.js'
    n.async = !0

    # these are the custom attributes for the widget behavior
    n.setAttribute 'data-embed-version', '2.1'
    n.setAttribute 'data-widget-id', id
    n.setAttribute 'data-start-hidden', yes

    c.parentNode.insertBefore n, c

    # configure the client so it doesn't look shitty
    _chatlio.configure
      titleColor                : "#01AF5B"
      titleFontColor            : "#fff"
      onlineTitle               : "How can we help you?"
      offlineTitle              : "Contact Us"
      agentLabel                : "Support"
      browserSideAuthorLabel    : "You"
      onlineMessagePlaceholder  : "Type message here..."
      offlineGreeting           : "Sorry we are away, but we would love to hear from you and chat soon!"
      offlineEmailPlaceholder   : "Email"
      offlineMessagePlaceholder : "Your message here"
      offlineNamePlaceholder    : "Name (optional but helpful)"
      offlineSendButton         : "Send"
      offlineThankYouMessage    : "Thanks for your message. We will be in touch soon!"
      autoResponseMessage       : "Question? Just type it below and we are online and ready to answer."

    # these to identify the user talking
    # taken from user's koding account
    account = whoami()

    account.fetchEmail (err, email) ->

      _chatlio.identify account.profile.nickname,
        name  : getFullnameFromAccount account
        email : email
        team  : team.slug

    # show when message received
    document.addEventListener 'chatlio.messageReceived', -> _chatlio.show  { expanded: yes }



module.exports = setupChatlio = ->

  { groupsController } = kd.singletons

  groupsController.ready ->

    team      = groupsController.getCurrentGroup()
    chatlioId = team.customize?.chatlioId
    { roles } = globals.config

    # if user is an admin or owner
    # their support requests should
    # come to koding support not to
    # their slack they set up w/ chatlio
    if ('admin' in roles) or ('owner' in roles)
      chatlioId = KODING_CHATLIO_KEY

    return  unless chatlioId

    bootChatlio chatlioId, team