kd = require 'kd'
module.exports = class RegisterOptions extends kd.View
  viewAppended: ->

    inFrame = kd.runningInFrame()

    @addSubView optionsHolder = new kd.CustomHTMLView
      tagName  : 'ul'
      cssClass : 'login-options'

    optionsHolder.addSubView new kd.CustomHTMLView
      tagName  : 'li'
      cssClass : 'koding active'
      partial  : 'koding'
      tooltip  :
        title  : "<p class='login-tip'>Register with Koding</p>"

    optionsHolder.addSubView new kd.CustomHTMLView
      tagName  : 'li'
      cssClass : "github active #{if inFrame then 'hidden' else ''}"
      partial  : 'github'
      click    : -> kd.getSingleton('oauthController').openPopup 'github'
      tooltip  :
        title  : "<p class='login-tip'>Register with GitHub</p>"
