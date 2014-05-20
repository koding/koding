class ActivityContentDisplay extends KDScrollView

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
        KD.singleton('display').emit "ContentDisplayWantsToBeHidden", @
        KD.singleton('router').back()

    @back = new KDCustomHTMLView  unless KD.isLoggedIn()
