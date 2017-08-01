kd             = require 'kd'
$              = require 'jquery'
utils          = require './../core/utils'

MainHeaderView = require './../core/mainheaderview'
FindTeamForm   = require './findteamform'
FindTeamHelper = require './findteamhelper'

EMPTY_TEAM_LIST_ERROR = 'Empty team list'
SOLO_USER_ERROR = 'Solo user detected'

FAREWELL_SOLO_URL = 'https://www.koding.com/farewell-solo'

track = (action, properties = {}) ->

  properties.category = 'Teams'
  properties.label    = 'FindTeam'
  utils.analytics.track action, properties


module.exports = class FindTeamView extends kd.TabPaneView



  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new FindTeamForm
      callback : @bound 'findTeam'

    @back        = new kd.CustomHTMLView
      tagName    : 'a'
      cssClass   : 'TeamsModal-button-link'
      partial    : 'BACK'
      attributes : { href : '/Teams' }

    @createTeam  = new kd.CustomHTMLView
      tagName    : 'a'
      partial    : 'create a new team'
      attributes : { href : '/Teams/Create' }

    @on 'PaneDidShow', => @form.reloadRecaptcha()


  setFocus: -> @form.setFocus()


  findTeam: (formData) ->

    track 'submitted find teams form'

    FindTeamHelper.submitRequest formData,
      error   : (xhr) =>
        { responseText } = xhr
        @handleServerError responseText
        @form.button.hideLoader()
      success : =>
        @form.button.hideLoader()
        @form.reset()

        @showNotification 'Check your email', 'We\'ve sent you a list of your teams.'

        kd.singletons.router.handleRoute '/'


  handleServerError: (err) ->

    return location.assign FAREWELL_SOLO_URL  if err is SOLO_USER_ERROR

    err = 'We couldn\'t find any teams that you have joined or was invited!'  if err is EMPTY_TEAM_LIST_ERROR
    @showNotification err


  showNotification: (title, content) ->

    new kd.NotificationView
      cssClass : 'recoverConfirmation'
      title    : title
      content  : content
      duration : 4500


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--findTeam">
      <h4>Find My Teams</h4>
      <h5>We will email you the list of teams you are part of.</h5>
      {{> @form}}
      {{> @back}}
    </div>
    <div class="additional-info">
      Do you want to {{> @createTeam}}?
    </div>
    <div class="ufo-bg"></div>
    <div class="ground-bg"></div>
    <div class="footer-bg"></div>
    '''
