kd             = require 'kd'
$              = require 'jquery'
utils          = require './../core/utils'
JView          = require './../core/jview'
MainHeaderView = require './../core/mainheaderview'
FindTeamForm   = require './findteamform'

track = (action) ->

  category = 'Teams'
  label    = 'FindTeam'
  utils.analytics.track action, { category, label }


module.exports = class FindTeamView extends kd.TabPaneView

  JView.mixin @prototype

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


  setFocus: -> @form.setFocus()


  findTeam: (formData) ->

    track 'submitted find teams form'

    { email } = formData
    utils.findTeam email,
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
