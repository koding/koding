kd              = require 'kd'
JView           = require 'app/jview'
FooterView      = require 'app/commonviews/footerview'
remote          = require('app/remote').getInstance()

module.exports = class TeamsAppView extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController, router } = kd.singletons

    @soon = new kd.CustomHTMLView
      cssClass : 'ribbon'
      partial  : '<span>Coming Soon!</span>'

    @thanks = new kd.CustomHTMLView
      cssClass : 'ribbon hidden'
      partial  : '<span>Thank You!</span>'

    @title = new kd.CustomHTMLView
      tagName : 'h1'
      partial : 'Announcing Koding for Teams!'

    @subTitle = new kd.CustomHTMLView
      tagName  : 'h2'
      partial  : 'Imagine <span><i>your-company.koding.com</i><i>your-university.koding.com</i><i>your-class.koding.com</i><i>your-project.koding.com</i></span>'

    @button = new kd.ButtonView
      title       : 'Sign up for early access'
      style       : 'solid medium green'
      attributes  : testpath : 'signup-company-button-loggedin'
      callback    : =>

        {JUser} = remote.api

        JUser.fetchUser (err, user) =>

          if not user or err
            return new KDNotificationView
              title    : 'Something went wrong, please try again later!'
              duration : 3000

          $.ajax
            url        : "/-/teams/early-access"
            data       :
              campaign : 'teams-early-access'
              email    : user.email
            type       : 'POST'
            success    : @bound 'earlyAccessSuccess'
            error      : @bound 'earlyAccessFailure'


    @features = new kd.CustomHTMLView
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

    @soon.hide()
    @animateTargets()



  earlyAccessFailure: ({responseText}) ->

    if responseText is 'Already applied!'
      responseText = 'Thank you! We\'ll let you know when we launch it!'
      @$('form').hide()
      @soon.hide()
      @thanks.show()

    new kd.NotificationView
      title    : responseText
      duration : 3000


  earlyAccessSuccess: ->

    @$('form').hide()
    @soon.hide()
    @thanks.show()
    new kd.NotificationView
      title    : "We'll let you know when we launch it!"
      duration : 3000


  animateTargets: ->

    $els = @subTitle.$('span i')
    i    = 0
    kd.utils.repeat 2000, ->
      $els.css 'opacity', 0
      $els[i].style.opacity = 1
      i = if i is $els.length - 1 then 0 else i + 1


  pistachio: ->

    """
    <section class='main-wrapper'>
      {{> @title}}
      {{> @subTitle}}
      <form class='TeamsModal--middle login-form'>{{> @button}}</form>
      {{> @soon}}
      {{> @thanks}}
      {{> @features}}
    </section>
    """
