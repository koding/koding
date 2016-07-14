kd              = require 'kd'
$               = require 'jquery'
utils           = require './../../core/utils'
JView           = require './../../core/jview'
MainHeaderView  = require './../../core/mainheaderview'
ResetInlineForm = require './../../login/resetform'

track = (action) ->

  category = 'Team'
  label    = 'ResetForm'
  utils.analytics.track action, { category, label }


module.exports = class TeamResetTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @logo = utils.getGroupLogo()

    @form = new ResetInlineForm
      cssClass : 'login-form clearfix'
      callback : @bound 'doReset'

    @form.button.unsetClass 'solid medium green'
    @form.button.setClass 'TeamsModal-button TeamsModal-button--green'


  doReset: (formData) ->

    track 'submitted reset form'

    { recoveryToken, password, mode } = formData

    $.ajax
      url       : '/Reset'
      data      : { recoveryToken, password, _csrf : Cookies.get '_csrf' }
      type      : 'POST'
      error     : (xhr) =>
        { responseText } = xhr
        @resetForm.button.hideLoader()
        new kd.NotificationView { title : responseText }
      success   : ({ username }) =>
        @form.button.hideLoader()
        @form.reset()

        new kd.NotificationView
          title: 'Password changed, you can login now'

        route = if mode is 'join' then '/Join' else '/'
        kd.singletons.router.handleRoute route


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      <h4>Set your new password</h4>
      {{> @form}}
    </div>
    <footer>
      <a href="https://www.koding.com/legal/teams-user-policy" target="_blank">Acceptable user policy</a><a href="https://www.koding.com/legal/teams-copyright" target="_blank">Copyright/DMCA guidelines</a><a href="https://www.koding.com/legal/teams-terms-of-service" target="_blank">Terms of service</a><a href="https://www.koding.com/legal/teams-privacy" target="_blank">Privacy policy</a>
    </footer>
    '''
