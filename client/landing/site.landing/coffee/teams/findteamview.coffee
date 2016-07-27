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
      cssClass : 'logo-header'

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
      <h4>Find My Teams</h4>
      <h5>We will email you the list of teams you are part of.</h5>
      {{> @form}}
    </div>
    <div class="additional-info">
      Do you want to onboard a new team?<br />
      <a href="/Teams/Create" class="back-link" target="_self">Create a new account</a>
    </footer>
    '''
