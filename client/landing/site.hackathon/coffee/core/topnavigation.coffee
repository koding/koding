CustomLinkView = require './customlinkview'

module.exports = class TopNavigation extends KDCustomHTMLView

  menu = []

  if KD.whoami().type isnt 'registered'
    menu.push
      title : 'SIGN IN'
      href  : '/WFGH/Login'
      name  : 'login'

  constructor: (options = {}, data) ->

    options.tagName or= 'nav'

    super options, data

    @menu = {}

    {mainView} = KD.singletons
    mainView.on 'MainTabPaneShown', @bound 'setActiveItem'


  viewAppended: ->

    @createItem options  for options in menu
    @setPartial """
      <ul class="social-buttons clearfix">
        <li>
            <a href="http://twitter.com/share" class="socialite twitter-share" data-text="JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" data-url="http://koding.com/WFGH" data-count="none" rel="nofollow" target="_blank"><span class="vhidden">Share on Twitter</span></a>
        </li>
        <li>
            <a href="https://plus.google.com/share?url=http://koding.com/WFGH" data-annotation="none" class="socialite googleplus-one" data-size="tall" data-href="http://koding.com/WFGH" rel="nofollow" target="_blank"><span class="vhidden">Share on Google+</span></a>
        </li>
        <li>
            <a href="http://www.facebook.com/sharer.php?u=http://koding.com/WFGH&t=JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" class="socialite facebook-like" data-colorscheme="light" data-href="http://koding.com/WFGH" data-send="false" data-layout="button" data-width="60" data-show-faces="false" rel="nofollow" target="_blank"><span class="vhidden">Share on Facebook</span></a>
        </li>
        <li>
            <a href="http://www.linkedin.com/shareArticle?mini=true&url=http://koding.com/WFGH&title=JOIN THE WORLD'S FIRST GLOBAL HACKATHON #WFGH @koding" data-annotation="none" class="socialite linkedin-share" data-url="http://koding.com/WFGH" data-counter="none" rel="nofollow" target="_blank"><span class="vhidden">Share on LinkedIn</span></a>
        </li>
      </ul>
      """
    Socialite.load $('ul.social-buttons')[0]
    KD.utils.wait 5000, ->
      $('ul.social-buttons').addClass 'loaded'




  createItem: (options) ->

    options.cssClass = options.name.toLowerCase()

    @addSubView @menu[options.name] = new CustomLinkView options


  setActiveItem: (pane) ->

    @unsetActiveItems()

    {name} = pane

    @menu[name]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu

