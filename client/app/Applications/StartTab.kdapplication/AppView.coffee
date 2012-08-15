class StartTabMainView extends JView

  constructor:(options, data)->

    options.cssClass or= 'start-tab'

    super

    @appIcons = {}
    @listenWindowResize()

    mainView = @getSingleton('mainView')
    
    # mainView.sidebar.finderResizeHandle.on "DragInAction", =>
    #   log "DragInAction", mainView.contentPanel.getWidth()
    
    # mainView.sidebar.finderResizeHandle.on "DragFinished", =>
    #   @utils.wait 301, =>
    #     log "DragFinished", mainView.contentPanel.getWidth()
    
    @loader = new KDLoaderView
      size          :
        width       : 128
        height      : 128
      loaderOptions :
        diameter    : 128
        # speed       : 1
        density     : 70
        color       : "#ff9200"

    @button = new KDButtonView
      cssClass : "editor-button"
      title    : "refresh apps"
      loader   : yes
      callback : =>
        @removeAppIcons()
        @loader.show()
        @getSingleton("kodingAppsController").refreshApps (err, apps)=>
          @loader.hide()
          @button.hideLoader()
          @decorateApps apps

    @clear = new KDButtonView
      cssClass : "editor-button"
      title    : "clear appstorage"
      callback : =>
        @loader.show()
        @removeAppIcons()
        appManager.fetchStorage "KodingApps", "1.0", (err, storage)=>
          storage.update $set : { "bucket.apps" : {} }, =>
            @loader.hide()
            log arguments, "kodingAppsController storage cleared"
    
    @appItemContainer = new AppItemContainer
      cssClass : 'app-item-container'
      delegate : @

    @noAppsWarning = new KDView
      cssClass : 'no-apps hidden'
      partial  : 'you have no apps!'

    @recentFilesWrapper = new KDView
      cssClass : 'file-container'
  
  viewAppended:->

    super
    # @addApps()
    @addRealApps()
    @addSplitOptions()
    @addRecentFiles()

  _windowDidResize:->

    

  addApps:->
    
    for app in apps
      @appItemContainer.addSubView new StartTabOldAppView 
        tab : @
      , app
  
  pistachio:->
    """
    <h1 class="kdview start-tab-header">To start from a new file, select an editor <span>or open an existing file from your file tree</span></h1>
    <div class='hidden1'>{{> @loader}}</div>
    <div class='app-button-holder hidden1'>
      {{> @button}}
      {{> @clear}}
    </div>
    {{> @appItemContainer}}
    {{> @noAppsWarning}}
    <div class='start-tab-split-options expanded'>
      <h3>Start with a workspace</h3>
    </div>
    <div class='start-tab-recent-container'>
      <h3>Recent files:</h3>
      {{> @recentFilesWrapper}}
    </div>
    """
  
  addRealApps:->
    
    @removeAppIcons()
    @loader.show()

    @getSingleton("kodingAppsController").fetchApps (err, apps)=>
      @loader.hide()
      @decorateApps apps

  decorateApps:(apps)->

    if apps
      @noAppsWarning.hide()
      @putAppIcons apps
    else
      @noAppsWarning.show()

  removeAppIcons:->
    
    @appItemContainer.destroySubViews()
    @appIcons = {}

  putAppIcons:(apps)->

    @button.show()
    @loader.hide()
    for app, manifest of apps
      do (app, manifest)=>
        @appItemContainer.addSubView @appIcons[manifest.name] = new StartTabAppView
          click   : (pubInst, event)=>
            if event.metaKey
              pubInst.showLoader()
              delete KDApps[manifest.name]
              @getSingleton("kodingAppsController").getApp manifest.name, =>
                pubInst.hideLoader()
            else
              pubInst.showLoader()
              @runApp manifest, =>
                pubInst.hideLoader()
        , manifest

  runApp:(manifest, callback)->

    @getSingleton("kodingAppsController").getApp manifest.name, (appScript)=>
      mainView = @getSingleton('mainView')
      mainView.mainTabView.showPaneByView
        name         : manifest.name
        hiddenHandle : no
        type         : "application"
      , (appView = new KDView)
      callback?()
      # security please!
      eval appScript
      return appView

  addSplitOptions:->
    for splitOption in getSplitOptions()
      option = new KDCustomHTMLView
        tagName   : 'a'
        cssClass  : 'start-tab-split-option'
        partial   : splitOption.partial
        click     : -> appManager.notify()
      @addSubView option, '.start-tab-split-options'

  addRecentFiles:->

    @recentFileViews = {}
    
    appManager.fetchStorage 'Finder', '1.0', (err, storage)=>

      storage.on "update", => @updateRecentFileViews()

      if err
        error "couldn't fetch the app storage.", err
      else
        recentFilePaths = storage.getAt('bucket.recentFiles')
        @updateRecentFileViews()
        @getSingleton('mainController').on "NoSuchFile", (file)=>
          recentFilePaths.splice recentFilePaths.indexOf(file.path), 1
          # log "updating storage", recentFilePaths.length
          storage.update { 
            $set: 'bucket.recentFiles': recentFilePaths
          }, => log "storage updated"
          

  updateRecentFileViews:()->
    
    appManager.fetchStorage 'Finder', '1.0', (err, storage)=>

      recentFilePaths = storage.getAt('bucket.recentFiles')
      # log "updating views", recentFilePaths.length
    
      for path, view of @recentFileViews
        @recentFileViews[path].destroy()
        delete @recentFileViews[path]
    
      if recentFilePaths?.length
        recentFilePaths.forEach (filePath)=>
          @recentFileViews[filePath] = new StartTabRecentFileView {}, filePath
          @recentFilesWrapper.addSubView @recentFileViews[filePath]
      else
        @recentFilesWrapper.hide()

  createSplitView:(type)->

  getSplitOptions = ->
    [
      {
        partial               : '<span class="fl w50"></span><span class="fr w50"></span>'
        splitType             : 'vertical'
        splittingFromStartTab : yes
        splits                : [1,1]
      },
      {
        partial               : '<span class="fl h50 w50"></span><span class="fr h50 w50"></span><span class="h50 full-b"></span>'
        splitType             : 'horizontal'
        secondSplitType       : 'vertical'
        splittingFromStartTab : yes
        splits                : [2,1]
      },
      {
        partial               : '<span class="h50 full-t"></span><span class="fl w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'horizontal'
        secondSplitType       : 'vertical'
        splittingFromStartTab : yes
        splits                : [1,2]
      },
      {
        partial               : '<span class="fl w50 h50"></span><span class="fr w50 full-r"></span><span class="fl w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [2,1]
      },
      {
        partial               : '<span class="fl w50 full-l"></span><span class="fr w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [1,2]
      },
      {
        partial               : '<span class="fl w50 h50"></span><span class="fr w50 h50"></span><span class="fl w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [2,2]
      },
    ]

  apps = [
    {
      name      : 'Ace Editor'
      type      : 'Code Editor'
      appToOpen : 'Ace'
      image     : '../images/icn-ace.png'
    },
    {
      name      : 'CodeMirror'
      type      : 'Code Editor'
      appToOpen : 'CodeMirror'
      image     : '../images/icn-codemirror.png'
      disabled  : yes
    },
    {
      name      : 'yMacs'
      type      : 'Code Editor'
      appToOpen : 'YMacs'
      image     : '../images/icn-ymacs.png'
      disabled  : yes
    },
    {
      name      : 'Pixlr'
      type      : 'Image Editor'
      appToOpen : 'Pixlr'
      image     : '../images/icn-pixlr.png'
      disabled  : yes
    },
    {
      name      : 'Get more...'
      appToOpen : 'Apps'
      image     : '../images/icn-appcatalog.png'
      catalog   : yes
    }
  ]


class AppItemContainer extends KDView
  parentDidResize:->
    # log @getDelegate().getHeight()

class StartTabAppView extends JView

  constructor:(options, data)->

    options.tagName    = 'figure'
    options.attributes = href : '#'
    
    if data.disabled? 
      options.cssClass += ' disabled'
    else if data.catalog? 
      options.cssClass += ' appcatalog'

    super options, data
    
    {icns} = @getData()
    @imgHolder = new KDView
      tagName : "p"
      partial : "<img src=\"#{icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}\" />"

    @loader = new KDLoaderView
      size          :
        width       : 40

  showLoader:->
  
    @loader.show()
    @imgHolder.$().css "opacity", "0.5"

  hideLoader:->

    @loader.hide()
    @imgHolder.$().css "opacity", "1"

  pistachio:->
    """
      {{> @loader}}
      {{> @imgHolder}}
      <strong>{{ #(name)}} {{ #(version)}}</strong>
      <span>{{ #(type)}}</span>
    """

class StartTabOldAppView extends KDView
  
  constructor:(options, data)->
    newClass = if data.disabled? then 'start-tab-item disabled' else if data.catalog? then 'start-tab-item appcatalog' else 'start-tab-item'
    options = $.extend
      tagName     : 'figure'
      cssClass    : newClass
    , options
    super options, data
    
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    
  pistachio:->
    {image} = @getData()
    """
      <img src="#{image}" />
      <strong>{{ #(name)}}</strong>
      <span>{{ #(type)}}</span>
    """
    
  click:(event)->
    {appToOpen, disabled} = @getData()
    {tab}                 = @getOptions()
    if appToOpen isnt "Apps"
      appManager.replaceStartTabWithApplication appToOpen, tab unless disabled
    else 
      appManager.openApplication appToOpen


class StartTabRecentFileView extends JView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      cssClass    : 'start-tab-recent-file'
      tooltip     :
        title     : "<p class='file-path'>#{data}</p>"
        template  : '<div class="twipsy-arrow"></div><div class="twipsy-inner twipsy-inner-wide"></div>'
    , options
    super options, data
    
  pistachio:->
    path = @getData()
    name = (path.split '/')[(path.split '/').length - 1]
    extension = __utils.getFileExtension name
    fileType  = __utils.getFileType extension
    
    """
      <div class='finder-item file clearfix'>
        <span class='icon #{fileType} #{extension}'></span>
        <span class='title'>#{name}</span>
      </div>
    """
    
  click:(event)->
    # appManager.notify()
    file = FSHelper.createFileFromPath @getData()
    file.fetchContents (err, contents)=>
      if err
        if /No such file or directory/.test err
          @getSingleton('mainController').emit "NoSuchFile", file
          new KDNotificationView
            title     : "This file is deleted in server!"
            type      : "mini"
            container : @parent
            cssClass  : "error"
      else
        file.contents = contents
        appManager.openFile file
      
      