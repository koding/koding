kd = require 'kd'
module.exports = class LoginOptions extends kd.View
  viewAppended: ->

    inFrame = kd.runningInFrame()

    @addSubView new kd.HeaderView
      type      : 'small'
      title     : 'SIGN IN WITH:'

    @addSubView optionsHolder = new kd.CustomHTMLView
      tagName   : 'ul'
      cssClass  : 'login-options'

    optionsHolder.addSubView new kd.CustomHTMLView
      tagName   : 'li'
      cssClass  : 'koding active'
      partial   : 'koding'
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Koding</p>"

    optionsHolder.addSubView new kd.CustomHTMLView
      tagName   : 'li'
      cssClass  : "github #{if inFrame then 'hidden' else ''}"
      partial   : 'github'
      click     : ->
        return new kd.NotificationView { title: 'Login restricted' }
        #kd.singletons.oauthController.openPopup "github"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with GitHub</p>"
