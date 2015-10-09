kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDSlideShowView = kd.SlideShowView
AnimatedModalView = require '../commonviews/animatedmodalview'
HelpPage = require '../helppage'
module.exports = class HelpModal extends AnimatedModalView

  links =
    noob : [
      { title : 'What is Koding?', url : 'http://learn.koding.com/what-is-koding/' }
      { title : 'Getting Started', url : 'http://learn.koding.com/gettingstarted/' }
      { title : 'Development on Koding', url : 'http://learn.koding.com/development-on-koding/' }
      { title : '<i>Tutorial:</i> EmberJS', url : 'http://learn.koding.com/emberjs-starting-kit/' }
      { title : '<i>Tutorial:</i> Octopress', url : 'http://learn.koding.com/octopress-installation-beginners/' }
      { title : '<i>Tutorial:</i> Ghost Blog', url : 'http://learn.koding.com/developing-ghost-blog-koding/' }
      { title : '<i>Tutorial:</i> Bootstrap 3', url : 'http://learn.koding.com/bootstrap-3-quick-tip/' }
      { title : 'Terminal', url : '/Terminal', command:'help this' }
    ]
    experienced : [
      { title : 'Koding subdomains and Vhosts', url : 'http://learn.koding.com/koding-subdomains-and-vhosts/' }
      { title : 'How to setup Octopress', url : 'http://learn.koding.com/63/' }
      { title : 'Codeigniter Installation', url : 'http://learn.koding.com/codeigniter-beginners/' }
      { title : 'Firebase setup and usage', url : 'http://learn.koding.com/getting-started-firebase/' }
      { title : 'Getting started with Facebook Application Development', url : 'http://learn.koding.com/getting-started-with-facebook-application-development/' }
      { title : 'sudo password', url : '/Terminal', command:'help sudo' }
    ]
    advanced : [
      { title : 'Terminal and custom ports', url : 'http://learn.koding.com/terminal-and-custom-ports/' }
      { title : 'Using Tmux on Koding', url : 'http://learn.koding.com/using-tmux-on-koding/' }
      { title : 'sudo password', url : '/Terminal', command:'help sudo' }
    ]
    commons : [
      { title : 'FAQ', url : 'http://learn.koding.com/faq/' }
      { title : 'FTP', url : '/Terminal', command:'help ftp' }
      { title : 'MySQL', url : '/Terminal', command:'help mysql' }
      { title : 'phpMyAdmin', url : '/Terminal', command:'help phpmyadmin' }
      { title : 'MongoDB', url : '/Terminal', command:'help mongodb' }
      { title : 'VM Specs', url : '/Terminal', command:'help specs' }
      { title : 'Preinstalled packages', url : '/Terminal', command:'help programs' }
    ]

  constructor:(options, data)->

    options.cssClass     = 'kdhelp-modal'
    options.overlay      = yes
    options.overlayClick = yes

    super options, data

    @slider = new KDSlideShowView
      cssClass     : 'help-content'
      direction    : 'leftToRight'
      touchEnabled : no

    @addSubView new KDCustomHTMLView
      partial      : """
        <h2>Welcome on board!</h2>
        <p>Let us try to help you find your way in Koding. Are you:</p>
        """

    @addSubView buttonContainer = new KDCustomHTMLView
      cssClass : "button-container"

    buttonContainer.on 'deselectAll', ->
      @$('a').removeClass 'active'

    @on 'InternalLinkClicked', (link)=>
      kd.utils.defer => @destroy()

    {slider} = this

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'active'
      attributes : href : '#'
      partial    : "new to<br/>programming"
      click      : (event)->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 0

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '#'
      partial    : "an experienced<br/>developer"
      click      : (event)->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 1

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '#'
      partial    : "an advanced<br/>programmer"
      click      : (event)->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 2

    @addSubView @slider

    @slider.addPage noob = new HelpPage
      delegate : this
    ,
      title    : "New to programming? No worries we got you covered!"

    noob.addLinks links.noob
    noob.addLinks links.commons

    @slider.addPage experienced = new HelpPage
      delegate : this
    ,
      title    : "You may find these topics below helpful:"

    experienced.addLinks links.experienced
    experienced.addLinks links.commons

    @slider.addPage advanced = new HelpPage
      delegate : this
    ,
      title    : "Welcome to <code>$ sudo su</code> world in the cloud"

    advanced.addLinks links.advanced
    advanced.addLinks links.commons

    @addSubView new KDCustomHTMLView
      tagName  :'footer'
      partial  : """
        <h4>Find more at <a href='http://learn.koding.com'>Koding University</a>, also we would love to hear your <a href='https://docs.google.com/forms/d/1jxdnXLm-cgHDpokzKIJSaShEirb66huoEMhPkQF5f_I/viewform'target='_blank'>feedback</a>.</h4>
      """
