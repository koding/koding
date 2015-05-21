JView = require './../../core/jview'

module.exports = class TeamLoginAndCreateTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @addCustomData 'username', KD.utils.getTeamData().signup.email
    @password = new KDInputView
      type          : 'password'
      name          : 'password'
      placeholder   : 'password'
      validate      :
        event       : 'blur'
        rules       :
          required  : yes
        messages    :
          required  : 'Please enter a password.'

    @button = new KDButtonView
      title      : 'Continue to environmental setup'
      style      : 'TeamsModal-button TeamsModal-button--green'
      attributes : testpath : 'register-button'
      type       : 'submit'


  pistachio: ->

    """
    <div class='login-input-view'><span>Password</span>{{> @password}}</div>
    {{> @button}}
    """