kd                     = require 'kd'
globals                = require 'globals'

whoami                 = require 'app/util/whoami'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
fetchIntercomKey       = require 'app/util/fetchIntercomKey'
intercomSupport        = require 'app/util/intercomSupport'

module.exports = setupIntercom = ->

  do setSmall = -> setTimeout ->
    if i = document.getElementById 'intercom-container'
    then setTimeout (-> i.classList = 'small'), 1000
    else setSmall()
  , 2000

  fetchIntercomKey (intercomAppId) ->
    return  unless intercomAppId

    w  = window
    ic = w.Intercom

    if typeof ic is 'function'
      ic 'reattach_activator'
      ic 'update', w.intercomSettings ? {}
    else
      d = document
      i = -> i.c arguments
      i.q = []
      i.c = (args) -> i.q.push args
      w.Intercom = i

      s = d.createElement 'script'
      s.type  = 'text/javascript'
      s.async = yes
      s.src = "https://widget.intercom.io/widget/#{intercomAppId}"
      x = d.getElementsByTagName('script')[0]
      x.parentNode.insertBefore s, x

      intercomSupport (isSupported) ->
        account = whoami()
        window.Intercom 'boot',
          app_id  : intercomAppId
          name    : getFullnameFromAccount account
          email   : globals.userEmail
          user_id : account._id
          hide_default_launcher : not isSupported
