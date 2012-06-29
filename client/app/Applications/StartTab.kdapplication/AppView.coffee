class StartTabMainView extends KDView
  constructor:(options, data)->
    options = $.extend
      cssClass      : 'start-tab'
    , options
    super options, data
    @listenWindowResize()
    
  viewAppended:()->
    @addApps()
    @addSplitOptions()
    @addRecentFiles()
    
  addApps:->
    mainView = @
    @addSubView appView = new KDView
      cssClass      : 'start-tab-app-container'
    appView.addSubView new KDView
      tagName   : "h1"
      cssClass  : "start-tab-header"
      partial   : 'To start from a new file, select an editor <span>or open an existing file from your file tree</span>'
    appView.addSubView appItemContainer = new AppItemContainer { cssClass: 'app-item-container', delegate : mainView }
    for app in @apps
      appItemContainer.addSubView new StartTabAppView 
        tab       : @
      , app
      
  addSplitOptions:->

    @addSubView splitOptionsView = new KDView
      cssClass    : 'start-tab-split-options'
    splitOptionsView.addSubView new KDView
      tagName     : 'h3'
      partial     : 'Start with a workspace'
    for splitOption in @splitOptions
      splitOptionsView.addSubView new SplitOptionsLink 
        tab       : @
      , splitOption
    
    splitOptionsView.setClass 'expanded'  
    
    
  addRecentFiles:->

    @addSubView @recentFilesWrapper = new KDView
      cssClass    : 'start-tab-recent-container file-container'
    
    @recentFilesWrapper.addSubView new KDView
      tagName     : 'h3'
      partial     : 'Recent Files'
    
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

  apps : [
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
      name      : 'Get more editors in the Koding App Catalog'
      appToOpen : 'Apps'
      image     : '../images/icn-appcatalog.png'
      catalog   : yes
    }
  ]
  
  splitOptions : [
    {
      partial               : '<div class="full-vert-l" /><div class="full-vert-r" />'
      splitType             : 'vertical'
      splittingFromStartTab : yes
      splits                : [1,1]
    },
    {
      partial               : '<div class="half-horiz-l" /><div class="half-horiz-r" /><div class="full-horiz-b" />'
      splitType             : 'horizontal'
      secondSplitType       : 'vertical'
      splittingFromStartTab : yes
      splits                : [2,1]
    },
    {
      partial               : '<div class="full-horiz-t" /><div class="half-horiz-l" /><div class="half-horiz-r" />'
      splitType             : 'horizontal'
      secondSplitType       : 'vertical'
      splittingFromStartTab : yes
      splits                : [1,2]
    },
    {
      partial               : '<div class="full-vert-r" /><div class="half-vert-t" /><div class="half-vert-b" />'
      splitType             : 'vertical'
      secondSplitType       : 'horizontal'
      splittingFromStartTab : yes
      splits                : [2,1]
    },
    {
      partial               : '<div class="full-vert-l" /><div class="half-vert-t-r" /><div class="half-vert-b-r" />'
      splitType             : 'vertical'
      secondSplitType       : 'horizontal'
      splittingFromStartTab : yes
      splits                : [1,2]
    },
    {
      partial               : '<div class="half-horiz-l-t" /><div class="half-horiz-r-t" /><div class="half-horiz-l" /><div class="half-horiz-r" />'
      splitType             : 'vertical'
      secondSplitType       : 'horizontal'
      splittingFromStartTab : yes
      splits                : [2,2]
    },
  ]
  
  
  createSplitView:(type)->

class AppItemContainer extends KDView
  parentDidResize:->
    # log @getDelegate().getHeight()

class StartTabAppView extends KDView
  constructor:(options, data)->
    newClass = if data.disabled? then 'start-tab-item disabled' else if data.catalog? then 'start-tab-item appcatalog' else 'start-tab-item'
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
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

class SplitOptionsLink extends KDView
  constructor:(options, data)->
    newPartial = data.partial
    options = $.extend
      tagName     : 'a'
      cssClass    : 'start-tab-split-option'
      partial     : newPartial
    , options
    super options, data
    
  click:(event)->
    appManager.notify()
    # {tab} = @getOptions()
    # appManager.replaceStartTabWithSplit @getData(), tab
      
      