kd      = require 'kd'
utils   = require './../core/utils'
JView   = require './../core/jview'


module.exports = class TeamsSelectorForm extends kd.FormView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    teams    = utils.getPreviousTeams()
    lastTeam = teams?.latest

    @inputView = new kd.CustomHTMLView
      cssClass     : 'login-input-view'
      click        : => @input.setFocus()

    @inputView.addSubView @input = new kd.InputView
      placeholder  : 'Your team name...'
      name         : 'slug'
      defaultValue : lastTeam  if lastTeam

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : ".#{kd.config.domains.main}"


    @button = new kd.ButtonView
      title       : 'Login'
      icon        : yes
      style       : 'TeamsModal-button'
      attributes  : { testpath : 'goto-team-button' }
      type        : 'submit'

    @input.on 'ValidationFeedbackCleared', =>
      @inputView.unsetClass 'validation-error validation-passed'


  pistachio: ->

    """
    {{> @inputView}}
    <div class='submit'>{{> @button}}</div>
    """
