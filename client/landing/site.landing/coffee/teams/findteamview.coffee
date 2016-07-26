kd             = require 'kd'
$              = require 'jquery'
utils          = require './../core/utils'
JView          = require './../core/jview'
FindTeamForm   = require './findteamform'

track = (action) ->

  category = 'Team'
  label    = 'FindTeam'
  utils.analytics.track action, { category, label }


module.exports = class FindTeamView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team Teams-findteam', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new kd.CustomHTMLView
      tagName  : 'header'
      cssClass : 'Homepage-Header'

    @header.addSubView new kd.CustomHTMLView
      tagName   : 'a'
      partial   : '<img src="/a/images/logos/header_logo.svg" />'
      click     : (event) ->
        kd.utils.stopDOMEvent event
        kd.singletons.router.handleRoute '/'

    @form = new FindTeamForm
      callback : @bound 'findTeam'


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
      {{> @form}}
    </div>
    '''
