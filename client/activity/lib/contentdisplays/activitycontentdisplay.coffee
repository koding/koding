kd = require 'kd'
KDScrollView = kd.ScrollView
KDCustomHTMLView = kd.CustomHTMLView
JView = require 'app/jview'
HeaderViewSection = require 'app/commonviews/headerviewsection'
isLoggedIn = require 'app/util/isLoggedIn'


module.exports = class ActivityContentDisplay extends KDScrollView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass or= "content-display activity-related #{options.type}"

    super options, data

    @header = new HeaderViewSection
      type    : "big"
      title   : @getOptions().title

    @back   = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)=>
        event.stopPropagation()
        event.preventDefault()
        kd.singleton('display').emit "ContentDisplayWantsToBeHidden", @
        kd.singleton('router').back()

    @back = new KDCustomHTMLView  unless isLoggedIn()
