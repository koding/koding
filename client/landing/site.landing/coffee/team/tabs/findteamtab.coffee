kd             = require 'kd'
$              = require 'jquery'
utils          = require '../../core/utils'
JView          = require '../../core/jview'
MainHeaderView = require '../../core/mainheaderview'
FindTeamForm   = require '../forms/findteamform'

track = (action) ->

  category = 'Team'
  label    = 'FindTeam'
  utils.analytics.track action, { category, label }


module.exports = class FindTeamTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @logo = utils.getGroupLogo()

    @form = new FindTeamForm
      cssClass : 'login-form clearfix'
      callback : @bound 'findTeam'

    @form.button.unsetClass 'solid medium green'
    @form.button.setClass 'TeamsModal-button TeamsModal-button--green'


  setFocus: -> @form.setFocus()


  findTeam: (formData) ->

    track 'submitted find teams form'

    { email } = formData
    group = utils.getGroupNameFromLocation()

    $.ajax
      url         : '/findteam'
      data        : { email, _csrf : Cookies.get('_csrf'), group }
      type        : 'POST'
      error       : (xhr) =>
        { responseText } = xhr
        new kd.NotificationView { title : responseText }
        @form.button.hideLoader()
      success     : =>
        @form.button.hideLoader()
        @form.reset()

        new kd.NotificationView
          cssClass : 'recoverConfirmation'
          title    : 'Check your email'
          content  : 'We\'ve sent you a list of your teams.'
          duration : 4500

        kd.singletons.router.handleRoute '/'


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      {{> @form}}
    </div>
    <footer>
      <a href="https://www.koding.com/legal/teams-user-policy" target="_blank">Acceptable user policy</a><a href="https://www.koding.com/legal/teams-copyright" target="_blank">Copyright/DMCA guidelines</a><a href="https://www.koding.com/legal/teams-terms-of-service" target="_blank">Terms of service</a><a href="https://www.koding.com/legal/teams-privacy" target="_blank">Privacy policy</a>
    </footer>
    '''
