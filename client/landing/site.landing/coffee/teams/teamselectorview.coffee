kd                = require 'kd.js'
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


  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @form = new TeamsSelectorForm
      callback : @bound 'goToTeam'

    @previousTeams = new kd.CustomHTMLView

    teams = utils.getPreviousTeams()

    return  unless teams


    suffix = if Object.keys(teams).length > 2 then 'these teams' else 'this team'

    @previousTeams.addSubView new kd.CustomHTMLView
      tagName : 'p'
      partial : "You previously visited #{suffix}:<br/>"

    for slug, title of teams when slug isnt 'latest'
      @previousTeams.addSubView new kd.CustomHTMLView
        tagName    : 'a'
        cssClass   : 'previous-team'
        partial    : title
        attributes :
          href     : "#{location.protocol}//#{slug}.#{location.host}"


  goToTeam: (formData) ->

    { slug } = formData

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
    <div class="TeamsModal TeamsModal--select TeamsModal--domain">
      <h4>Sign in to your team</h4>
      <h5>Enter your team's <b>Koding</b> domain.</h5>
      {{> @form}}
    </div>
    <section class="previous-teams">
      <p>Trying to create a team? <a href="//#{utils.getMainDomain()}/Teams/Create" target="_self">Click here</a> to get started.</p>
      {{> @previousTeams}}
    </section>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """
