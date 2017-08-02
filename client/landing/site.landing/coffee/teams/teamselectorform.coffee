kd             = require 'kd'
utils          = require './../core/utils'

LoginInputView = require './../login/logininputview'

module.exports = class TeamsSelectorForm extends kd.FormView



  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    teams    = utils.getPreviousTeams()
    lastTeam = teams?.latest

    @teamName = new LoginInputView
      inputOptions   :
        label        : 'Team URL'
        placeholder  : 'your-team-name'
        name         : 'slug'
        defaultValue : lastTeam  if lastTeam

    @suffix = new kd.View
      tagName      : 'span'
      cssClass     : 'TeamDomainSuffix'
      partial      : ".#{kd.config.domains.main}"


    @button = new kd.ButtonView
      title       : 'Login'
      icon        : yes
      style       : 'TeamsModal-button'
      attributes  : { testpath : 'goto-team-button' }
      type        : 'submit'

    @teamName.input.on 'ValidationFeedbackCleared', =>
      @teamName.input.unsetClass 'validation-error validation-passed'


  pistachio: ->

    """
    {{> @teamName }}
    {{> @suffix }}
    <div class='submit'>{{> @button }}</div>
    """
