kd                = require 'kd'
utils             = require './../core/utils'
MainHeaderView    = require './../core/mainheaderview'
JView             = require './../core/jview'
LoginInputView    = require './../login/logininputview'
TeamsSelectorForm = require './teamselectorform'


track = (action, entry) ->

  category = 'TeamSelector'
  label    = 'TeamSelector'
  entry    = entry

  utils.analytics.track action, { category, label, entry }


module.exports = class TeamSelectorView extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Login',    href : '/Teams',     name : 'login' }
      ]

    @form = new TeamsSelectorForm
      callback : @bound 'goToTeam'

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

    track 'navigated to team login page', slug

    utils.checkIfGroupExists slug, (err, group) ->

      if err
        return new kd.NotificationView
          title: 'We couldn\'t find your team.'

      location.assign "#{location.protocol}//#{slug}.#{location.host}"


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--select TeamsModal--domain not-supported-for-mobile">
      <h4>Apologies earthling!</h4>
      <hr></hr>
      <p>We don't currently support</br>using Koding on mobile devices.</p>
    </div>
    <div class="TeamsModal TeamsModal--select TeamsModal--domain TeamsModal-login">
      <h4>Sign in to your team</h4>
      <h5>Enter your team's <b>Koding</b> domain.</h5>
      {{> @form}}
    </div>
    <section class="previous-teams">
      <p>Trying to create a team? <a href="/Teams/Create" target="_self">Click here</a> to get started.</p>
      {{> @previousTeams}}
      <p>Looking for <a href="/Login" target="_self" testpath="koding-solo-login">Koding Solo</a>?</p>
    </section>
    """
