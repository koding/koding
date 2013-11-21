class MembersMainView extends KDView

  createCommons:->

    @addSubView @header = new HeaderViewSection
      type  : "big"
      title : "Members"

    KD.getSingleton("mainController").on 'AccountChanged', @bound 'setSearchInput'
    @setSearchInput()

  setSearchInput:->
    @header.setSearchInput()  if 'list members' in KD.config.permissions

class MembersLocationView extends KDCustomHTMLView
  constructor: (options, data) ->
    options = $.extend {tagName: 'p', cssClass: 'place'}, options
    super options, data

  viewAppended: ->
    locations = @getData()
    @setPartial locations?[0] or ''

class MembersLikedContentDisplayView extends KDView

  constructor:(options = {}, data)->

    options.view     or= mainView = new KDView
    options.cssClass or= 'member-followers content-page-members'

    super options, data

  createCommons:(account)->

    name = KD.utils.getFullnameFromAccount account

    contentDisplayController = KD.getSingleton "contentDisplayController"
    headerTitle              = "Activities which #{name} liked"

    @addSubView header = new HeaderViewSection
      type  : "big"
      title : headerTitle

    @addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : => contentDisplayController.emit "ContentDisplayWantsToBeHidden", @
    subHeader.addSubView backLink  if KD.isLoggedIn()

    @listenWindowResize()



class MembersContentDisplayView extends KDView
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
      cssClass : 'member-followers content-page-members'
    ,options

    super options, data

  createCommons:(account, filter)->

    name = KD.utils.getFullnameFromAccount account

    if filter is "following"
    then title = "Members who #{name} follows"
    else title = "Members who follow #{name}"

    @addSubView header = new HeaderViewSection {type : "big", title}

    @addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)=>
        event.preventDefault()
        event.stopPropagation()
        KD.getSingleton('contentDisplayController').emit "ContentDisplayWantsToBeHidden", @

    subHeader.addSubView backLink  if KD.isLoggedIn()

    @listenWindowResize()
