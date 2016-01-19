CustomLinkView             = require './../core/customlinkview'
MainHeaderView             = require './../core/mainheaderview'
JView                      = require './../core/jview'
FooterView                 = require './../home/footerview'
TeamsHomeFeaturesSection   = require './partials/teamshomefeaturessection'
TeamsSignupForm            = require './teamssignupform'
TeamsLaunchForm            = require './teamslaunchform'


module.exports = class TeamsWaitListView extends JView


  constructor:(options = {}, data)->

    super options, data

    { mainController, router } = KD.singletons

    teamsLogo = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'teams-header-logo'
      partial   : '<cite>Koding</cite> Teams'
      click     : (event) ->
        KD.utils.stopDOMEvent event
        KD.singletons.router.handleRoute '/'

    @thanks = new KDCustomHTMLView
      cssClass : 'ribbon hidden'
      partial  : '<span>Thank You!</span>'

    @comingSoon = new KDCustomHTMLView
      cssClass : 'ribbon hidden'
      partial  : '<span>Coming Soon!</span>'

    @header = new MainHeaderView
      headerLogo : teamsLogo
      cssClass   : 'hasNotTeamAccess'
      navItems  : [
        { title : 'Koding University', href : 'http://learn.koding.com',  name : 'about' }
        { title : 'Features',          href : '/Features',                name : 'features' }
      ]

    @title = new KDCustomHTMLView
      tagName : 'h1'
      partial : 'Announcing Koding for Teams!'

    @subTitle = new KDCustomHTMLView
      tagName  : 'h2'
      partial  : '<span><i>your-company.koding.com</i><i>your-university.koding.com</i><i>your-class.koding.com</i><i>your-project.koding.com</i></span>'

    @form = new TeamsLaunchForm
      cssClass : 'TeamsModal--middle login-form pre-launch'
      callback : (formData) =>
        KD.utils.earlyAccess formData,
          success : @bound 'earlyAccessSuccess'
          error   : @bound 'earlyAccessFailure'

    @features = new KDCustomHTMLView
      tagName : 'ul'
      partial : """

        <li><i>Reduce setup time</i> for new team members.</li>
        <li>Treat your <i>infrastructure as code</i>. Easy to manage and even easier to upgrade!</li>
        <li>Predefine the <i>compute resources</i> that your team should have.</li>
        <li>Collaborate using <i>video/audio</i> without the need to install anything!</li>
        <li><i>Most cloud-providers</i> are supported so you can use your existing infrastructure.</li>
        <li>Integrate common services like <i>GitHub</i>, <i>Pivotal</i>, <i>Asana</i>, etc. into your Koding environment.</li>
        <li style='list-style-type:none;'>Learn more on our <a href='http://blog.koding.com/teams' target='_blank'>blog</a>.</li>
        """

    @animateTargets()
    @comingSoon.show()



  earlyAccessFailure: ({responseText}) ->

    if responseText is 'Already applied!'
      responseText = 'Thank you! We\'ll let you know when we launch it!'
      @form.hide()
      @comingSoon.hide()
      @thanks.show()

    new KDNotificationView
      title    : responseText
      duration : 3000


  earlyAccessSuccess: ->

    @form.hide()
    @comingSoon.hide()
    @thanks.show()
    new KDNotificationView
      title    : "We'll let you know when we launch it!"
      duration : 3000


  animateTargets: ->

    $els = @subTitle.$('span i')
    i    = 0
    KD.utils.repeat 2000, ->
      $els.css 'opacity', 0
      $els[i].style.opacity = 1
      i = if i is $els.length - 1 then 0 else i + 1


  pistachio: ->

    """
    {{> @header }}
    <section class='main-wrapper'>
      {{> @title}}
      {{> @subTitle}}
      {{> @form}}
      {{> @thanks}}
      {{> @comingSoon}}
      {{> @features}}
    </section>
    """
