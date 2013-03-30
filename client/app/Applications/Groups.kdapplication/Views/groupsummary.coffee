class GroupSummaryView extends KDCustomHTMLView

  constructor:(options = {}, data = {})->

    options.domId = "group-summary"

    super options, data

    @loader = new KDLoaderView
      size          :
        width       : 60
      loaderOptions :
        color       : "#ffffff"


    @sign = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "group-logo-wrapper"
      bind        : "mouseenter mouseleave"
      pistachio   : """
        <i></i><i></i>
        <h3 id="group-logo">{{#(title)}}</h3>
        """
      mouseenter  : -> @$().css marginTop : 13
      mouseleave  : -> @$().css marginTop : 8
      click       : @bound "showSummary"
    , {}

    @landingPageLink = new CustomLinkView
      cssClass : "public-page-link"
      title    : "Go to public page of this group"
      click    : @bound "goToPublicPage"

    @once "viewAppended", @loader.bound "show"
    @once "viewAppended", @bound "decorateSummary"

  viewAppended: JView::viewAppended

  pistachio:->
    """
      {{> @loader}}
      <header>
        <div class='avatar-wrapper'></div>
        <div class='right-overflow'></div>
      </header>
      <aside></aside>
      {{> @landingPageLink}}
      {{> @sign}}
    """
  click:->
    @unsetClass "down"
    @utils.wait 400, =>
      @sign.setClass "swing-in"

  showSummary:(event)->
    event.stopPropagation()
    @sign.setClass "swing-out"
    @sign.unsetClass "swing-in"
    @utils.wait 400, =>
      @sign.unsetClass "swing-out"
      @setClass "down"

  hideSummary:->
    @unsetClass "down"
    @utils.wait 400, =>
      @sign.unsetClass "swing-out"
      @sign.unsetClass "swing-in"

  decorateSummary:->

    KD.remote.cacheable KD.config.groupEntryPoint, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        @sign.setData group
        @sign.render()

        group.fetchAdmin (err, owner)=>
          if err then warn err
          else
            @loader.hide()
            @putOwner owner

        group.fetchMembers (err, members)=>
          if err then warn err
          else
            log members

  putOwner:(owner)->

    ownerAvatar = new AvatarView
      cssClass  : "owner"
      size      :
        width   : 60
        height  : 60
    , owner

    @addSubView ownerAvatar, '.avatar-wrapper'

    title = new KDHeaderView
      type  : "medium"
      title : "#{@utils.getFullnameFromAccount owner} created this group."

    @addSubView title, '.right-overflow'

  goToPublicPage:(event)->

    event.stopPropagation()
    event.preventDefault()
    @hideSummary()
    @utils.wait 300, =>
      @getSingleton("lazyDomController").showLandingPage()
