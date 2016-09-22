kd             = require 'kd'
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
      placeholder  : 'Your team name...'
      name         : 'slug'

    @input.on 'ValidationFeedbackCleared', =>
      @inputView.unsetClass 'validation-error validation-passed'

    @inputView.addSubView @suffix = new kd.View
      tagName      : 'span'
      partial      : ".#{kd.config.domains.main}"

    @backLink = new kd.CustomHTMLView
      tagName    : 'a'
      cssClass   : 'TeamsModal-button-link'
      partial    : 'BACK'
      attributes : { href : '/Teams/Create' }

    @button = new kd.ButtonView
      title        : 'NEXT'
      style        : 'TeamsModal-button'
      attributes   : { testpath  : 'domain-button' }
      type         : 'submit'


  pistachio: ->

    # <p class='dim'>Your team url can only contain lowercase letters numbers and dashes.</p>
    """
    {{> @inputView}}
    {{> @button}}
    {{> @backLink}}
    """
