kd      = require 'kd.js'
utils   = require './../core/utils'
JView   = require './../core/jview'


module.exports = class TeamsSelectorForm extends kd.FormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    teams    = utils.getPreviousTeams()
    lastTeam = teams?.latest

    @inputView = new kd.CustomHTMLView
      cssClass     : 'login-input-view'
      click        : => @input.setFocus()

    @inputView.addSubView @input = new kd.InputView
      placeholder  : 'your-team'
      attributes   : 10
      name         : 'slug'
      defaultValue : lastTeam  if lastTeam

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : '.koding.com'

    @inputView.addSubView @fakeView = new kd.CustomHTMLView
      tagName      : 'div'
      cssClass     : 'fake-view'

    @button = new kd.ButtonView
      title       : 'Continue'
      icon        : yes
      style       : 'TeamsModal-button TeamsModal-button--green'
      attributes  : testpath : 'goto-team-button'
      type        : 'submit'

    @input.on 'ValidationFeedbackCleared', =>
      @inputView.unsetClass 'validation-error validation-passed'

    # Listen text change event in real time
    @input.on [ 'input', 'viewAppended' ], @bound 'repositionSuffix'


  repositionSuffix: ->

    @input.getElement().removeAttribute 'size'
    element           = @fakeView.getElement()
    element.innerHTML = @input.getValue()
    { width }         = element.getBoundingClientRect()
    @input.setWidth width or 100


  pistachio: ->

    """
    {{> @inputView}}
    <div class='TeamsModal-button-separator'></div>
    <div class='submit'>{{> @button}}</div>
    """