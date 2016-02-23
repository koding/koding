kd             = require 'kd.js'
utils          = require './../../core/utils'
JView          = require './../../core/jview'
MainHeaderView = require './../../core/mainheaderview'

module.exports = class TeamDomainTab extends kd.FormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix login-form'

    super options, data

    team = utils.getTeamData()

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
    @input.on 'input', =>
      @input.getElement().removeAttribute 'size'

      element           = @fakeView.getElement()
      element.innerHTML = @input.getValue()
      { width }         = element.getBoundingClientRect()
      @input.setWidth width or 100

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : '.koding.com'

    @inputView.addSubView @fakeView = new kd.CustomHTMLView
      tagName      : 'div'
      cssClass     : 'fake-view'

    @backLink = new kd.CustomHTMLView
      tagName      : 'span'
      cssClass     : 'TeamsModal-button-link back'
      partial      : "<i></i> <a href=\"/Teams/#{team.invitation.teamAccessCode}\">Back</a>"

    @button = new kd.ButtonView
      title        : 'NEXT'
      style        : 'TeamsModal-button TeamsModal-button--green'
      attributes   : testpath  : 'domain-button'
      type         : 'submit'


  pistachio: ->

    # <p class='dim'>Your team url can only contain lowercase letters numbers and dashes.</p>
    """
    {{> @inputView}}
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @backLink}}
    """
