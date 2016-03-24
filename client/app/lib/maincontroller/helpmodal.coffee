kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDSlideShowView = kd.SlideShowView
AnimatedModalView = require '../commonviews/animatedmodalview'
HelpPage = require '../helppage'
module.exports = class HelpModal extends AnimatedModalView

  links =
    noob : [
      { title : 'What is Koding?', url : 'https://koding.com/docs/what-is-koding/' }
      { title : 'Getting Started', url : 'https://koding.com/docs/getting-started/' }
      { title : 'Development on Koding', url : 'https://koding.com/docs/ide-introduction/' }
      { title : '<i>Tutorial:</i> EmberJS', url : 'https://koding.com/docs/emberjs-starting-kit/' }
      { title : '<i>Tutorial:</i> Octopress', url : 'https://koding.com/docs/octopress-for-beginners/' }
      { title : '<i>Tutorial:</i> Ghost Blog', url : 'https://koding.com/docs/ghost-installation/' }
      { title : 'Terminal', url : '/Terminal', command:'help this' }
    ]
    experienced : [
      { title : 'Koding subdomains and Vhosts', url : 'https://koding.com/docs/vhosts-and-subdomains' }
      { title : 'How to setup Octopress', url : 'https://koding.com/docs/octopress-for-beginners/' }
      { title : 'Codeigniter Installation', url : 'https://koding.com/docs/codeigniter-for-beginners' }
      { title : 'sudo password', url : '/Terminal', command:'help sudo' }
    ]
    advanced : [
      { title : 'Terminal and custom ports', url : 'https://koding.com/docs/terminal-and-custom-ports/' }
      { title : 'Using Tmux on Koding', url : 'https://koding.com/docs/using-tmux-on-koding/' }
      { title : 'sudo password', url : '/Terminal', command:'help sudo' }
    ]
    commons : [
      { title : 'FAQ', url : 'https://koding.com/docs/topic/faq/' }
      { title : 'FTP', url : '/Terminal', command:'help ftp' }
      { title : 'MySQL', url : '/Terminal', command:'help mysql' }
      { title : 'phpMyAdmin', url : '/Terminal', command:'help phpmyadmin' }
      { title : 'MongoDB', url : '/Terminal', command:'help mongodb' }
      { title : 'VM Specs', url : '/Terminal', command:'help specs' }
      { title : 'Preinstalled packages', url : '/Terminal', command:'help programs' }
    ]

  constructor: (options, data) ->

    options.cssClass     = 'kdhelp-modal'
    options.overlay      = yes
    options.overlayClick = yes

    super options, data

    @slider = new KDSlideShowView
      cssClass     : 'help-content'
      direction    : 'leftToRight'
      touchEnabled : no

    @addSubView new KDCustomHTMLView
      partial      : '''
        <h2>Welcome on board!</h2>
        <p>Let us try to help you find your way in Koding. Are you:</p>
        '''

    @addSubView buttonContainer = new KDCustomHTMLView
      cssClass : 'button-container'

    buttonContainer.on 'deselectAll', ->
      @$('a').removeClass 'active'

    @on 'InternalLinkClicked', (link) =>
      kd.utils.defer => @destroy()

    { slider } = this

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'active'
      attributes : { href : '#' }
      partial    : 'new to<br/>programming'
      click      : (event) ->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 0

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : { href : '#' }
      partial    : 'an experienced<br/>developer'
      click      : (event) ->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 1

    buttonContainer.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : { href : '#' }
      partial    : 'an advanced<br/>programmer'
      click      : (event) ->
        kd.utils.stopDOMEvent event
        buttonContainer.emit 'deselectAll'
        @setClass 'active'
        slider.jump 2

    @addSubView @slider

    @slider.addPage noob = new HelpPage
      delegate : this
    ,
      title    : 'New to programming? No worries we got you covered!'

    noob.addLinks links.noob
    noob.addLinks links.commons

    @slider.addPage experienced = new HelpPage
      delegate : this
    ,
      title    : 'You may find these topics below helpful:'

    experienced.addLinks links.experienced
    experienced.addLinks links.commons

    @slider.addPage advanced = new HelpPage
      delegate : this
    ,
      title    : 'Welcome to <code>$ sudo su</code> world in the cloud'

    advanced.addLinks links.advanced
    advanced.addLinks links.commons

    @addSubView new KDCustomHTMLView
      tagName  :'footer'
      partial  : """
        <h4>Find more at <a href='https://koding.com/docs'>Koding University</a>, also we would love to hear your <a href='https://docs.google.com/forms/d/1jxdnXLm-cgHDpokzKIJSaShEirb66huoEMhPkQF5f_I/viewform'target='_blank'>feedback</a>.</h4>
      """
