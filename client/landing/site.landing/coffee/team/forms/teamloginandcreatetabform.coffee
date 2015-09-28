JView = require './../../core/jview'

module.exports = class TeamLoginAndCreateTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    { username, email } = KD.utils.getTeamData().signup

    @username = new KDInputView
      placeholder      : 'email or username'
      name             : 'username'
      defaultValue     : email or username
      validate         :
        rules          :
          required     : yes
        messages       :
          required     : 'Please enter a username.'
        events         :
          required     : 'blur'

    @password = new KDInputView
      type          : 'password'
      name          : 'password'
      placeholder   : 'your password'
      validate      :
        event       : 'blur'
        rules       :
          required  : yes
        messages    :
          required  : 'Please enter a password.'

    @backLink = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link back'
      partial  : '← <a href="/Team/Domain">Back</a>'


    @button = new KDButtonView
      title      : 'Sign in'
      style      : 'TeamsModal-button TeamsModal-button--green'
      attributes : testpath : 'register-button'
      type       : 'submit'


  pistachio: ->

    """
    <div class='login-input-view'><span>Username</span>{{> @username}}</div>
    <div class='login-input-view'><span>Password</span>{{> @password}}</div>
    <div class='TeamsModal-button-separator'></div>
    {{> @backLink}}
    {{> @button}}
    """