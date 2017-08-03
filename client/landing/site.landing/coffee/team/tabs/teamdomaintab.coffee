kd                = require 'kd'
utils             = require './../../core/utils'

MainHeaderView    = require './../../core/mainheaderview'
TeamDomainTabForm = require './../forms/teamdomaintabform'

module.exports = class TeamDomainTab extends kd.TabPaneView



  constructor:(options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    name               = @getOption 'name'

    @header = new MainHeaderView { cssClass : 'team', navItems : [] }

    @form = new TeamDomainTabForm
      callback: (formData) =>

        track 'submitted domain form'

        formData.slug = formData.slug.toLowerCase?()
        utils.verifySlug formData.slug,
          success : =>
            track 'entered a valid domain'
            @form.teamName.input.parent.unsetClass 'validation-error'
            utils.storeNewTeamData name, formData
            # removed these steps
            # temp putting these empty values here to not break stuff - SY
            utils.storeNewTeamData 'email-domains', { domains : '' }
            utils.storeNewTeamData 'invite', { invitee1 : '', invitee2 : '', invitee3 : '' }

            route = if kd.config.environment is 'default'
            then '/Team/Username'
            else '/Team/Payment'

            kd.singletons.router.handleRoute route

          error   : (error) =>
            @showError error or 'That domain is invalid or taken, please try another one.'


  show: ->

    super

    team = utils.getTeamData()

    if slug = team.domain?.slug
    then teamName = slug
    else teamName = utils.slugifyCompanyName team

    { input } = @form.teamName

    input.setValue teamName
    input.emit 'input'
    input.emit 'ValidationFeedbackCleared'
    input.$().trigger 'focus'


  showError: (error) ->

    track 'entered an invalid domain'
    @form.teamName.input.parent.setClass 'validation-error'
    new kd.NotificationView { title : error }


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--domain">
      <h4>Your team URL</h4>
      <h5>Your team will use this to access your Koding Teams account.</h5>
      {{> @form}}
    </div>
    '''


track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'DomainTab'
  utils.analytics.track action, properties
