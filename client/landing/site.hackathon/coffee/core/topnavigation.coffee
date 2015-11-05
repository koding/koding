CustomLinkView = require './customlinkview'
TWEET_TEXT     = 'Join the world\'s first virtual global #hackathon by @koding. No matter where you are!'
SHARE_URL      = 'https://koding.com/Hackathon2014'

module.exports = class TopNavigation extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.tagName or= 'nav'

    super options, data

    @menu = {}


  viewAppended: ->

    @addSubView @addThis = new KDCustomHTMLView
      cssClass       : 'addthis_sharing_toolbox'
      attributes     :
        'data-title' : TWEET_TEXT
        'data-url'   : SHARE_URL

    repeater = KD.utils.repeat 200, ->
      if addthis?.layers?.refresh
        addthis.layers.refresh()
        KD.utils.killRepeat repeater




  setActiveItem: (pane) ->

  unsetActiveItems: ->
