JView             = require './../../core/jview'
MainHeaderView    = require './../../core/mainheaderview'
TeamDomainTabForm = require './../forms/teamdomaintabform'

module.exports = class TeamDomainTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    super options, data

    { mainController } = KD.singletons
    name               = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamDomainTabForm
      callback: (formData) =>

        track 'submitted domain form'

        formData.slug = formData.slug.toLowerCase?()
        KD.utils.verifySlug formData.slug,
          success : =>
            track 'entered a valid domain'
            @form.input.parent.unsetClass 'validation-error'
            KD.utils.storeNewTeamData name, formData
            # removed these steps
            # temp putting these empty values here to not break stuff - SY
            KD.utils.storeNewTeamData 'email-domains', domains : ''
            KD.utils.storeNewTeamData 'invite', invitee1 : '', invitee2 : '', invitee3 : ''
            KD.singletons.router.handleRoute '/Team/Username'

          error   : (error) =>
            @showError error or 'That domain is invalid or taken, please try another one.'


  show: ->

    super

    team = KD.utils.getTeamData()

    if slug = team.domain?.slug
    then teamName = slug
    else teamName = KD.utils.slugifyCompanyName team

    @form.input.setValue teamName
    @form.input.setAttribute 'size', teamName.length

    @form.input.emit 'ValidationFeedbackCleared'


  showError: (error) ->

    track 'entered an invalid domain'
    @form.input.parent.setClass 'validation-error'
    new KDNotificationView { title : error }


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Your team URL</h4>
      <h5>Your team will use this to access your Koding Teams account.</h5>
      {{> @form}}
    </div>
    """


track = (action) ->

  category = 'TeamSignup'
  label    = 'DomainTab'

  KD.utils.analytics.track action, { category, label }
