kd             = require 'kd'
utils          = require './../../core/utils'

LoginInputView = require './../../login/logininputview'

module.exports = class TeamDomainTabForm extends kd.FormView



  constructor: (options = {}, data) ->

    options.cssClass = 'clearfix login-form'

    super options, data


    @teamName = new LoginInputView
      inputOptions :
        label        : 'Your Team URL'
        placeholder  : 'your-team-name'
        name         : 'slug'

    @teamName.input.on 'ValidationFeedbackCleared', =>
      @teamName.input.unsetClass 'validation-error validation-passed'

    @suffix = new kd.View
      tagName      : 'span'
      cssClass     : 'TeamDomainSuffix'
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
    '''
    {{> @teamName }}
    {{> @suffix }}
    {{> @button }}
    {{> @backLink }}
    '''
