kd             = require 'kd.js'
utils          = require './../../core/utils'
JView          = require './../../core/jview'


module.exports = class TeamDomainTab extends kd.FormView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'clearfix login-form'

    super options, data


    @inputView = new kd.CustomHTMLView
      cssClass     : 'login-input-view'
      click        : => @input.setFocus()

    @inputView.addSubView @input = new kd.InputView
      placeholder  : 'your-team'
      attributes   : 10
      name         : 'slug'

    @input.on 'ValidationFeedbackCleared', =>
      @inputView.unsetClass 'validation-error validation-passed'

    # Listen text change event in real time
    @input.on [ 'input', 'viewAppended' ], => utils.repositionSuffix @input, @fakeView

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : '.koding.com'

    @inputView.addSubView @fakeView = new kd.CustomHTMLView
      tagName      : 'div'
      cssClass     : 'fake-view'

    @backLink = new kd.CustomHTMLView
      tagName      : 'span'
      cssClass     : 'TeamsModal-button-link back'
      partial      : '<i></i> <a href=\"/Teams/Create\">Back</a>'

    @button = new kd.ButtonView
      title        : 'NEXT'
      style        : 'TeamsModal-button TeamsModal-button--green'
      attributes   : { testpath  : 'domain-button' }
      type         : 'submit'


  pistachio: ->

    # <p class='dim'>Your team url can only contain lowercase letters numbers and dashes.</p>
    """
    {{> @inputView}}
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @backLink}}
    """
