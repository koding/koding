JView          = require './../../core/jview'
MainHeaderView = require './../../core/mainheaderview'

module.exports = class TeamDomainTab extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    team = KD.utils.getTeamData()

    if name = team.signup?.companyName
      teamName = KD.utils.slugify name

    @input = new KDInputView
      placeholder  : 'your-team'
      defaultValue : teamName  if teamName
      name         : 'slug'

    @backLink = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link back'
      partial  : '← <a href="/Teams">Back</a>'


    @button = new KDButtonView
      title      : 'NEXT'
      style      : 'TeamsModal-button TeamsModal-button--green'
      attributes : testpath  : 'domain-button'
      type       : 'submit'


  pistachio: ->

    # <p class='dim'>Your team url can only contain lowercase letters numbers and dashes.</p>
    """
    <div class='login-input-view'>{{> @input}}<span>.koding.com</span></div>
    <div class='TeamsModal-button-separator'></div>
    {{> @backLink}}
    {{> @button}}
    """