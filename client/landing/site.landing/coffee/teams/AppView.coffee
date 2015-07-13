CustomLinkView             = require './../core/customlinkview'
MainHeaderView             = require './../core/mainheaderview'
JView                      = require './../core/jview'
FooterView                 = require './../home/footerview'
TeamsHomeFeaturesSection   = require './partials/teamshomefeaturessection'
TeamsSignupForm            = require './teamssignupform'
TeamsLaunchForm            = require './teamslaunchform'


module.exports = class TeamsView extends JView


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


    if KD.config.hasTeamAccess

      @header = new MainHeaderView
        headerLogo : teamsLogo
        navItems : [
          { title : 'Success Stories',  href : 'http://blog.koding.com',  name : 'stories' }
          { title : 'Learn More',       href : '/Teams',                  name : 'learn' }
          { title : 'SIGN IN',          href : '/Team/Login',             name : 'buttonized yellow login',  attributes : testpath : 'login-link' }
        ]

      @title = new KDCustomHTMLView
        tagName : 'h1'
        partial : "Koding for Teams!"

      @subTitle = new KDCustomHTMLView
        tagName   : 'p'
        cssClass  : 'intro'
        partial   : 'Onboard, develop, deploy, test and work together with your team right away, without a setup!'

      @form = new TeamsSignupForm
        cssClass : 'TeamsModal--middle login-form'
        callback : (formData) ->
          go = ->
            KD.utils.storeNewTeamData 'signup', formData
            KD.singletons.router.handleRoute '/Team/Domain'

          { email } = formData
          KD.utils.validateEmail { email },
            success : -> formData.alreadyMember = no; go()
            error   : -> formData.alreadyMember = yes; go()

      @playVideoIcon = new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'icon play'
        click    : ->
          alert 'clicked'

      @teamsHomeFeaturesSection = new TeamsHomeFeaturesSection

      @features = new KDCustomHTMLView
        cssClass : 'hidden'

      @footer = new FooterView

    else

      @header = new MainHeaderView
        headerLogo : teamsLogo
        cssClass   : 'hasNotTeamAccess'
        navItems  : [
          { title : 'Blog',     href : 'http://blog.koding.com',  name : 'stories' }
          { title : 'Teams',    href : '/Teams',                  name : 'learn' }
          { title : 'SIGN IN',  href : '/Team/Login',             name : 'buttonized yellow login',  attributes : testpath : 'login-link' }
        ]

      @title = new KDCustomHTMLView
        tagName : 'h1'
        partial : 'Announcing Koding for Teams!'

      @subTitle = new KDCustomHTMLView
        tagName  : 'h2'
        partial  : 'Imagine <span><i>your-company.koding.com</i><i>your-university.koding.com</i><i>your-class.koding.com</i><i>your-project.koding.com</i></span>'

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

      @playVideoIcon = new KDCustomHTMLView
        cssClass : 'hidden'

      @footer = new KDCustomHTMLView
        cssClass : 'hidden'

      @teamsHomeFeaturesSection = new KDCustomHTMLView
        cssClass : 'hidden'

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

    hasTeamAccess = unless KD.config.hasTeamAccess then 'hasNotTeamAccess' else ''
    hiddenClass   = unless KD.config.hasTeamAccess then 'hidden' else ''

    """
    {{> @header }}
    <section class='main-wrapper #{hasTeamAccess}'>
      {{> @title}}
      {{> @subTitle}}
      {{> @form}}
      {{> @thanks}}
      {{> @comingSoon}}
      {{> @features}}
      <div class='embed-info #{hiddenClass}'>
          <img src='/a/site.landing/images/teams/text.png' alt='' />
          <span class='icon'></span>
      </div>
      <div class='embed-box #{hiddenClass}'>
        {{> @playVideoIcon}}
      </div>
    </section>
    {{> @teamsHomeFeaturesSection}}
    {{> @footer}}
    """
