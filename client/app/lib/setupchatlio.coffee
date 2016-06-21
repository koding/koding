kd                     = require 'kd'
whoami                 = require 'app/util/whoami'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
fetchChatlioKey        = require 'app/util/fetchChatlioKey'

shouldTalkToKodingSupport = no

bootChatlio = (id, team) ->

  # this thing is js to coffee of chatlio embed code
  window._chatlio = window._chatlio or []
  not do ->
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
    n.async = not 0

    # these are the custom attributes for the widget behavior
    n.setAttribute 'data-embed-version', '2.1'
    n.setAttribute 'data-widget-id', id
    n.setAttribute 'data-start-hidden', yes

    c.parentNode.insertBefore n, c

    # configure the client so it doesn't look shitty
    _chatlio.configure
      titleColor                : '#56A2D3'
      titleFontColor            : '#FFFFFF'
      agentLabel                : if shouldTalkToKodingSupport then 'Koding Support' else "#{team.title} Support"

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

    # hide completely when close icon clicked
    # default behavior is to minify
    document.addEventListener 'click', (event) ->
      return  unless event.target.classList.contains 'chatlio-icon-cross2'
      _chatlio.hide()



module.exports = setupChatlio = ->

  fetchChatlioKey (chatlioId, isAdmin) ->

    team = kd.singletons.groupsController.getCurrentGroup()
    shouldTalkToKodingSupport = isAdmin

    return  unless chatlioId

    bootChatlio chatlioId, team
