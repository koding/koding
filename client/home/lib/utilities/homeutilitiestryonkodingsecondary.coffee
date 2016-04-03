kd             = require 'kd'
JView          = require 'app/jview'
CustomLinkView = require 'app/customlinkview'

module.exports = class HomeUtilitiesTryOnKoding extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @guide  = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'VIEW GUIDE'
      href     : 'https://www.koding.com/docs/desktop-app'

    @download  = new CustomLinkView
      cssClass : 'HomeAppView--button primary'
      title    : 'DOWNLOAD'
      href     : 'https://www.koding.com/docs/desktop-app/download'

    @switch  = new CustomLinkView
      cssClass : 'HomeAppView--button primary'
      title    : 'SWITCH'
      href     : 'https://www.koding.com/docs/desktop-app/download'


  pistachio: ->
    """
    <p>
    <strong>Enable “Try On Koding” Button</strong>
    Visiting users will have access to all team stack scripts
    {{> @switch}}
    </p>
    """
