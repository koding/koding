kd                = require 'kd'
$                 = require 'jquery'
utils             = require './../../core/utils'

MainHeaderView    = require './../../core/mainheaderview'
RecoverInlineForm = require './../../login/recoverform'

track = (action, properties = {}) ->

  properties.category = 'Team'
  properties.label    = 'RecoverForm'
  utils.analytics.track action, properties

module.exports = class TeamRecoverTab extends kd.TabPaneView



  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @logo = utils.getGroupLogo()

    @form = new RecoverInlineForm
      cssClass : 'login-form clearfix'
      callback : @bound 'doRecover'

    @form.button.unsetClass 'solid medium green'
    @form.button.setClass 'TeamsModal-button'


  setFocus: -> @form.usernameOrEmail.input.setFocus()


  doRecover: (formData) ->

    track 'submitted recover form'

    { email, mode } = formData
    group = utils.getGroupNameFromLocation()

    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get('_csrf'), group, mode }
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
          content  : 'We\'ve sent you a password recovery code.'
          duration : 4500

        route = switch mode
          when 'join'   then '/Join'
          when 'create' then '/Team/Username'
          else ''

        kd.singletons.router.handleRoute route


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--login TeamsModal--recover">
      {{> @logo}}
      {{> @form}}
    </div>
    '''
