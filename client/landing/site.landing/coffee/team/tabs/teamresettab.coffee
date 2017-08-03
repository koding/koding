kd              = require 'kd'
$               = require 'jquery'
utils           = require './../../core/utils'

MainHeaderView  = require './../../core/mainheaderview'
ResetInlineForm = require './../../login/resetform'

track = (action, properties = {}) ->

  properties.category = 'Team'
  properties.label    = 'ResetForm'
  utils.analytics.track action, properties

module.exports = class TeamResetTab extends kd.TabPaneView



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
    @form.button.setClass 'TeamsModal-button'


  doReset: (formData) ->

    track 'submitted reset form'

    { recoveryToken, password, mode } = formData

    $.ajax
      url       : '/Reset'
      data      : { recoveryToken, password, _csrf : Cookies.get '_csrf' }
      type      : 'POST'
      error     : (xhr) =>
        { responseText } = xhr
        @form.button.hideLoader()
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
    '''
