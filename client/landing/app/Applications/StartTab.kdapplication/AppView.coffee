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

    @addSubView recentFilesView = new KDView
      cssClass    : 'start-tab-recent-container file-container'
    
    recentFilesView.addSubView new KDView
      tagName     : 'h3'
      partial     : 'Recent Files'
    
    appManager.getStorage 'Finder', '1.0', (err, storage)->
      if err
        error "couldn't fetch the app storage.", err
      else
        # recentFiles = storage.getAt('bucket.recentFiles')
        recentFiles = if storage.bucket?.recentFiles? then storage.bucket.recentFiles else []
        if recentFiles?.length
          recentFiles.forEach (file)->
            recentFilesView.addSubView new StartTabRecentFileView {}, file
        else
          recentFilesView.hide()
          # recentFilesView.addSubView new KDView
          #   cssClass    : 'start-tab-no-recent-files'
          #   partial     : "You don't have any recent files to look at."

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

class StartTabRecentFileView extends KDView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      cssClass    : 'start-tab-recent-file'
    , options
    super options, data
    
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    path = @getData()
    @$().twipsy
      title     : "<p class='file-path'>#{path}</p>"
      placement : "above"
      offset    : 0
      delayIn   : 300
      html      : yes
      animate   : yes
      template  : '<div class="twipsy-arrow"></div><div class="twipsy-inner twipsy-inner-wide"></div>'
    
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
    appManager.openFile FSHelper.createFileFromPath @getData()

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
      
      