JView             = require './../core/jview'

module.exports = class TeamAllowedDomainTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @label = new KDLabelView
      title : 'Allow sign up and team discovery with a company email address'
      for   : 'allow'

    @checkbox = new KDInputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'allow'
      label        : @label

    @input = new KDInputView
      placeholder : 'domain.com, other.edu'

    @button = new KDButtonView
      title       : 'NEXT'
      style       : 'SignupForm-button SignupForm-button--green'
      attributes  : testpath  : 'allowed-domain-button'
      loader      : yes
      callback    : =>
        console.log 'go to invites:'
        KD.singletons.router.handleRoute '/Team/invite'


  pistachio: ->

    """
    <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    <div class='login-input-view'><span>@</span>{{> @input}}</div>
    <p class='dim'>We guessed a domain for you based on your own email address.</p>
    {{> @button}}
    """