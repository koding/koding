kd                = require 'kd'
utils             = require './../core/utils'
MainHeaderView    = require './../core/mainheaderview'

LoginInputView    = require './../login/logininputview'
TeamsSelectorForm = require './teamselectorform'


track = (action, properties = {}) ->

  properties.category = 'TeamSelector'
  properties.label    = 'TeamSelector'
  utils.analytics.track action, properties

module.exports = class TeamSelectorView extends kd.TabPaneView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamsSelectorForm
      callback : @bound 'goToTeam'

    @findTeam    = new kd.CustomHTMLView
      tagName    : 'a'
      cssClass   : 'TeamsModal-button-link'
      partial    : 'Forgot your team name?'
      attributes : { href : '/Teams/FindTeam' }

    @createTeam  = new kd.CustomHTMLView
      tagName    : 'a'
      partial    : 'create a new team'
      attributes : { href : '/Teams/Create' }

    @previousTeams = new kd.CustomHTMLView { tagName: 'p' }

    teams = utils.getPreviousTeams()

    return  unless teams


    suffix = if Object.keys(teams).length > 2 then 'these teams' else 'this team'

    @previousTeams.addSubView new kd.CustomHTMLView
      tagName : 'span'
      partial : "You previously visited #{suffix}:"

    @previousTeams.addSubView ul = new kd.CustomHTMLView
      tagName : 'ul'

    for slug, title of teams when slug isnt 'latest'
      href = "#{location.protocol}//#{slug}.#{location.host}"
      ul.addSubView new kd.CustomHTMLView
        tagName    : 'li'
        partial    : "<a href=\"#{href}\" class=\"previous-team\">#{title}</a>"


  goToTeam: (formData) ->

    { slug } = formData
    slug     = slug.toLowerCase()

    return notify()  if slug is 'koding'

    track 'navigated to team login page', { entry: slug }

    utils.checkIfGroupExists slug, (err, group) ->

      if err
        return new kd.NotificationView
          title: 'We couldn\'t find your team.'

      location.assign "#{location.protocol}//#{slug}.#{location.host}/Login"


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--select TeamsModal--domain TeamsModal-login">
      <h4>Welcome!</h4>
      <h5>Enter your team's Koding domain.</h5>
      {{> @form}}
      {{> @findTeam}}
    </div>
    <section class="previous-teams additional-info">
      Do you want to {{> @createTeam}}?
      {{> @previousTeams}}
    </section>
    <div class="ufo-bg"></div>
    <div class="ground-bg"></div>
    <div class="footer-bg"></div>
    """
