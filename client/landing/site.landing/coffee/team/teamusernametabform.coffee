JView             = require './../core/jview'

module.exports = class TeamUsernameTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @label = new KDLabelView
      title : 'Occasionally Koding can share relevant announcements with me.'
      for   : 'newsletter'

    @checkbox = new KDInputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'newsletter'
      label        : @label

    @username = new KDInputView
      placeholder : 'username'

    @password = new KDInputView
      type        : 'password'
      placeholder : '*********'

    @button = new KDButtonView
      title       : 'Continue to environmental setup'
      style       : 'SignupForm-button SignupForm-button--green'
      attributes  : testpath  : 'register-button'
      loader      : yes
      callback    : =>
        console.log 'go to invites:'
        KD.singletons.router.handleRoute '/Team/invite'


  pistachio: ->

    """
    <div class='login-input-view'><span>Username</span>{{> @username}}</div>
    <div class='login-input-view'><span>Password</span>{{> @password}}</div>
    <p class='dim'>Your username  is how you will appear to other people on your team. Pick something others will recignize.</p>
    <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    {{> @button}}
    """