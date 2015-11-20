JView          = require './../../core/jview'
MainHeaderView = require './../../core/mainheaderview'

module.exports = class TeamDomainTab extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    team = KD.utils.getTeamData()

    if name = team.signup?.companyName
    then teamName = KD.utils.slugify name
    else teamName = ''

    @inputView = new KDCustomHTMLView
      cssClass     : 'login-input-view'
      click        : => @input.setFocus()

    @inputView.addSubView @input = new KDInputView
      placeholder  : 'your-team'
      defaultValue : teamName  if teamName
      attributes   : size : teamName.length or 10
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

    @inputView.addSubView @suffix = new KDView
      tagName      : 'span'
      partial      : '.koding.com'

    @inputView.addSubView @fakeView = new KDCustomHTMLView
      tagName      : 'div'
      cssClass     : 'fake-view'

    @backLink = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'TeamsModal-button-link back'
      partial      : "<i></i> <a href=\"/Teams/#{team.invitation.teamAccessCode}\">Back</a>"

    @button = new KDButtonView
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