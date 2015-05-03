JView             = require './../core/jview'
CustomLinkView    = require './../core/customlinkview'

module.exports = class TeamInviteTabForm extends KDFormView

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

    @input1 = new KDInputView placeholder : 'email@domain.com'
    @input2 = new KDInputView placeholder : 'email@domain.com'
    @input3 = new KDInputView placeholder : 'email@domain.com'
    @add = new KDButtonView
      title       : 'ADD INVITATION'
      style       : 'SignupForm-button compact SignupForm-button--gray add'

    @skip = new CustomLinkView
      title       : 'Skip this step'
      cssClass    : 'SignupForm-linkButton skip'
      href        : '/Team/username'

    @button = new KDButtonView
      title       : 'NEXT'
      style       : 'SignupForm-button SignupForm-button--green'
      attributes  : testpath  : 'invite-button'
      loader      : yes
      callback    : =>
        console.log 'go to username:'
        KD.singletons.router.handleRoute '/Team/username'


  pistachio: ->

    """
    <div class='login-input-view'>{{> @input1}}</div>
    <div class='login-input-view'>{{> @input2}}</div>
    <div class='login-input-view'>{{> @input3}}</div>
    {{> @add}}
    <p class='dim'>if you’d like, you can send invitations after you finish setting up your team.</p>
    {{> @skip}}{{> @button}}
    """