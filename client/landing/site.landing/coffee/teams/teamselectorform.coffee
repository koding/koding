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
      placeholder  : 'Your team'
      attributes   : 10
      name         : 'slug'
      defaultValue : lastTeam  if lastTeam

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : ".#{kd.config.domains.main}"

    @inputView.addSubView @fakeView = new kd.CustomHTMLView
      tagName      : 'div'
      cssClass     : 'fake-view'

    @button = new kd.ButtonView
      title       : 'Login'
      icon        : yes
      style       : 'TeamsModal-button TeamsModal-button--green'
      attributes  : { testpath : 'goto-team-button' }
      type        : 'submit'

    @input.on 'ValidationFeedbackCleared', =>
      @inputView.unsetClass 'validation-error validation-passed'

    # Listen text change event in real time
    @input.on [ 'input', 'viewAppended' ], => utils.repositionSuffix @input, @fakeView


  pistachio: ->

    """
    {{> @inputView}}
    <div class='submit'>{{> @button}}</div>
    <a href="/Teams/FindTeam" class="secondary-link" target="_self">Forgot your team name?</a>
    """
