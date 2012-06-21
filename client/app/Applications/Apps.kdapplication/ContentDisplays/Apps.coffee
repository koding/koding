class ContentDisplayControllerApps extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
        cssClass : 'apps content-display'
    ,options
      
    super options, data
  
  loadView:(mainView)->
    app = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "<span>&laquo;</span> Back"
      attributes  :
        href      : "#"
      click       : ->
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView
    
    contentDisplayController = @getSingleton "contentDisplayController"
    
    # mainView.addSubView wrapperView = new AppViewMainPanel {}, app
    
    mainView.addSubView appView = new AppView
      cssClass : "profilearea clearfix"
      delegate : mainView
    , app
    
    @innerNav = new SingleAppNavigation
    @tabs     = new KDTabView
      cssClass             : "app-info-tabs"
      hideHandleCloseIcons : yes
      hideHandleContainer  : yes
    @createTabs()
    mainView.addSubView appSplit = new ContentPageSplitBelowHeader
      views     : [@innerNav,@tabs]
      sizes     : [139,null]
      minimums  : [10,null]
      resizable : no
    
    appSplit._windowDidResize()
  
  createTabs:()->
    app = @getData()
    @tabs.addPane infoTab = new KDTabPaneView
      name : 'appinfo'
    @tabs.addPane screenshotsTab = new KDTabPaneView
      name : 'screenshots'

    infoTab.addSubView new CommonListHeader 
      title : "Application Info"
    infoTab.addSubView new AppInfoView
      cssClass : "info-wrapper"
    , app

    screenshotsListController = new KDListViewController
      view            : new KDListView
        subItemClass  : AppScreenshotsListItem
    ,
      items           : app.screenshots
    
    screenshotsTab.addSubView screenshotsListController.getView()
    # screenshotsListController.getView().addSubView new CommonListHeader 
    #   title : "Screenshots"
    # , null, yes

    @tabs.showPane infoTab
    
    @innerNav.registerListener
      KDEventTypes  : "CommonInnerNavigationListItemReceivedClick"
      listener      : @
      callback      : (pubInst,event)=>
        @tabs.showPaneByName event.type

class AppView extends KDView
  constructor:->
    super
    app = @getData()

    @followButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      states          : [
        "Follow", (callback)-> 
          callback? null
        "Unfollow", (callback)->
          callback? null
      ]
    , app

    @likeButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      states          : [
        "Like", (callback)-> 
          callback? null
        "Unlike", (callback)->
          callback? null
      ]
    , app

    @installButton = new KDButtonView
      title     : "Install Now"
      style     : "cupid-green"
      callback  : =>
        modalOptions = @sanitizeInstallModalOptions()
        modal = new KDModalViewWithForms
          title         : "Application configuration"
          width         : 500
          height        : "auto"
          overlay       : yes
          tabs          :
            navigable   : yes
            callback    : (formOutput)=>
              @createBashScript formOutput,app
              modal.destroy()
            forms       : modalOptions
          
        
  createBashScript:(formOutput,app)->
    bashScript = Encoder.htmlDecode app.attachments[0].content
    for key,value of formOutput
      bashScript = bashScript.replace "$#{key}","\"#{value}\""
    
    log bashScript

  sanitizeInstallModalOptions:->
    app     = @getData()
    reqs    = app.attachments[1].content
    modalOptions = JSON.parse Encoder.htmlDecode reqs
    count   = 0
    for tabName,options of modalOptions
      unless Object.keys(modalOptions).length - 1 is count
        options.buttons =
          Next    :
            title : "Next"
            style : "modal-clean-gray"
            type  : "submit"
      else
        options.buttons =
          Install :
            title : "INSTALL THE APP!"
            style : "cupid-green"
            type  : "submit"
      count++
    modalOptions

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  putThumb:(thumbnails = [])->
    if thumbnails.length > 0
      thumb = "<img src='/images/uploads/#{thumbnails[0].appThumb}'/>"
    else
      ""

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{ @putThumb #(thumbnails)}}</a>
      </span>
    </div>
    <section class="right-overflow">
      {h3.profilename{#(title)}}
      <div class="installerbar clearfix">
        {{> @installButton}}
        <div class="versionstats updateddate">Version ---<p>Updated: ---</p></div>
        <div class="versionscorecard">
          <div class="versionstats">{{#(counts.installed)}}<p>INSTALLS</p></div>
          <div class="versionstats">0{{#(counts.likes)}}<p>Likes</p></div>
          <div class="versionstats">{{#(counts.followers)}}<p>Followers</p></div>
        </div>
        <div class="appfollowlike">
          {{> @followButton}}
          {{> @likeButton}}
        </div>
      </div>
    </section>
    """

class AppInfoView extends KDScrollView
  constructor:->
    super
    app = @getData()
    script = app.attachments[0]
    reqs = app.attachments[1]
    scriptData = {syntax : script.syntax, content : Encoder.htmlEncode(script.content), title : ""}
    requirementsData = {syntax : reqs.syntax, content : Encoder.htmlEncode(reqs.content), title : ""}
    @installScript = new AppCodeSnippetView {}, scriptData
    @requirementsScript = new AppCodeSnippetView {}, requirementsData
    
  viewAppended:->
    app = @getData()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <header><a href='#'>About {{#(title)}}</a></header>
    <section>{{#(body)}}</section>
    <header><a href='#'>Technical Stuff</a></header>
    <section>
      <p>{{#(attachments.0.description)}}<p>
      {{> @installScript}}
      {{> @requirementsScript}}
    </section>
    """

class AppScreenshotsListItem extends KDListItemView

  partial :(data)->
    "<figure><img class='screenshot' src='/images/uploads/#{data.screenshot}'></figure>"
    

class AppScreenshotsView extends KDScrollView
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  putScreenshots:(screenshots)->
    app = @getData()
    log app,screenshots
    htmlStr = ""
    for set in app.screenshots
      htmlStr += "<figure><img class='screenshot' src='/images/uploads/#{set.screenshot}'></figure>"
    return htmlStr  

  pistachio:->
    """
    <header><a href='#'>{{#(title)}} Screenshots</a></header>
    {{ @putScreenshots #(screenshots)}}
    """
  