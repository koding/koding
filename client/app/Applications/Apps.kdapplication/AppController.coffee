class AppsAppController extends AppController
  constructor:(options, data)->
    options = $.extend
      view : new AppsMainView
        cssClass : "content-page appstore"
    ,options
    super options,data

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name  : 'Apps'
      data    : @getView()

  loadView:(mainView)->
    mainView.createCommons()
    @createFeed()

  createFeed:(view)->
    options =
      itemClass          : AppsListItemView
      limitPerPage          : 10
      noItemFoundText       : "There is no app."
      filter                :
        allApps             :
          title             : "All Apps"
          dataSource        : (selector, options, callback)=>
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        webApps             :
          title             : "Web Apps"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'web-app'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        kodingAddOns        :
          title             : "Add-ons"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'add-on'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        serverStacks        :
          title             : "Server Stacks"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'server-stack'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        frameworks          :
          title             : "Frameworks"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'framework'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
            callback 'Coming soon!'
        miscellaneous       :
          title             : "Miscellaneous"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'misc'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
      sort                  :
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.followers'  :
          title             : "Most popular"
          direction         : -1
        'counts.tagged'     :
          title             : "Most activity"
          direction         : -1
      help                  :
        subtitle            : "Learn About Apps"
        tooltip :
          title     : "<p class=\"bigtwipsy\">The App Catalog contains apps and Koding enhancements contributed to the community by users.</p>"
          placement : "above"
          offset    : 0
          delayIn   : 300
          html      : yes
          animate   : yes

    if KD.checkFlag 'super-admin'
      options.filter.waitsForApprove =
        title             : "New Apps"
        dataSource        : (selector, options, callback)=>
          selector.approved = no
          KD.remote.api.JApp.someWithRelationship selector, options, callback

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, (controller)=>
      # @getSingleton("kodingAppsController").fetchAppsFromDb (err, apps)=>
      #   log "Installed Apps:", apps
      for own name,listController of controller.resultsController.listControllers
        listController.getListView().on 'AppWantsToExpand', (app)->
          KD.getSingleton('router').handleRoute "/Apps/#{app.slug}", state: app

        listController.getListView().on "AppDeleted", =>
          log arguments, ">>>>>"

      @getView().addSubView controller.getView()
      @feedController = controller
      @emit 'ready'
      # @putAddAnAppButton()

  fetchAutoCompleteDataForTags:(inputValue,blacklist,callback)->
    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err,tags)->
      unless err
        callback? tags
      else
        log "there was an error fetching topics"

  updateApps:->
    @utils.wait 100, @feedController.changeActiveSort "meta.modifiedAt"

  createContentDisplay:(app, doShow = yes)->
    @showContentDisplay app

  showContentDisplay:(content, callback=->)->
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    callback contentDisplay

  putAddAnAppButton:->
    {facetsController} = @feedController
    innerNav = facetsController.getView()
    innerNav.addSubView addButton = new KDButtonView
      title     : "Add an App"
      style     : "small-gray"
      callback  : => @showAppSubmissionView()

  createApp:(formData, callback)->
    log formData,"in createApp"
    # log JSON.stringify formData
    KD.remote.api.JApp.create formData, (err, app)->
      callback? err,app

  showAppSubmissionView:->
    modal       = new AppSubmissionModal
    modal.$().css top : 75
    {modalTabs} = modal
    {forms}     = modalTabs
    modal.on "AppSubmissionFormSubmitted", (formData)=>
      @createApp formData, (err,res)=>
        unless err
          new KDNotificationView
            title : "App created successfully!"
          modal.destroy()
        else
          warn "there was an error creating the app",err
          new KDNotificationView
            title : "there was an error creating the app"

    modalTabs.on "PaneDidShow", (pane)=>
      # scriptForm = forms['Technical Stuff']
      # scriptForm.addCustomData "scriptCode", scriptForm.ace.getValue()
      # scriptForm.addCustomData "scriptSyntax", scriptForm.ace.getActiveSyntaxName()
      # scriptForm.addCustomData "requirementsCode", scriptForm.reqs.getValue()
      # scriptForm.addCustomData "requirementsSyntax", scriptForm.reqs.getActiveSyntaxName()
      if pane.name is "Review & Submission"
        @createAppSummary modal, pane

    # TAGS AUTOCOMPLETE
    selectedItemWrapper = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "tags-selected-item-wrapper clearfix"

    tagController = new TagAutoCompleteController
      name                : "meta.tag"
      type                : "tags"
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : TagAutoCompletedItemView
      outputWrapper       : selectedItemWrapper
      listWrapperCssClass : "tags"
      form                : forms['Technical Stuff']
      itemDataPath        : 'title'
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in tagController.getSelectedItemData() when 'function' is typeof data.getId)
        @fetchAutoCompleteDataForTags inputValue,blacklist,callback

    tagAutoComplete = tagController.getView()
    tagsField       = forms['Technical Stuff'].fields.Tags
    tagsField.addSubView tagAutoComplete
    tagsField.addSubView selectedItemWrapper

    modal.on "KDModalViewDestroyed", -> tagController.destroy()

    # # INSTALL SCRIPT ACE
    # scriptForm      = forms['Technical Stuff']
    # scriptField     = scriptForm.fields.Script
    #
    # scriptField.addSubView aceWrapper = new KDCustomHTMLView
    #   cssClass : "code-snip-holder dark-select"
    #
    # aceWrapper.addSubView scriptForm.ace = new MiniAceEditor
    #   defaultValue  : "# Type your install script here..."
    #   autoGrow      : yes
    #   path          : "~~~/dummy-path/dummy.coffee"
    #   name          : "dummy.coffee"
    #
    # scriptForm.ace.on 'sizes.height.change', (options) =>
    #   {height} = options
    #   scriptForm.ace.$().parent().height height + 25
    #
    # scriptForm.ace.refreshEditorView()
    # scriptForm.ace.saveSyntaxForExtension "coffee"

    # # REQUIREMENTS SCRIPT ACE
    # reqsField        = scriptForm.fields.Reqs
    #
    # reqsField.addSubView reqsWrapper = new KDCustomHTMLView
    #   cssClass : "code-snip-holder dark-select"
    #
    # reqsWrapper.addSubView scriptForm.reqs = new MiniAceEditor
    #   defaultValue  : "# Type your requirement options here..."
    #   autoGrow      : yes
    #   path          : "~~~/dummy-path/dummy.coffee"
    #   name          : "dummy.coffee"
    #
    # scriptForm.reqs.on 'sizes.height.change', (options) =>
    #   {height} = options
    #   scriptForm.ace.$().parent().height height + 55
    #
    # scriptForm.reqs.refreshEditorView()
    # scriptForm.reqs.saveSyntaxForExtension "coffee"

    # IMAGE UPLOADERS
    thumbField = forms.Visuals.fields.thumbnail
    thumbField.addSubView thumbUploader = new KDImageUploadView
      limit           : 1
      preview         : "thumbs"
      extensions      : null
      fileMaxSize     : 512
      totalMaxSize    : 512
      fieldName       : "thumbnails"
      convertToBlob   : yes
      actions         : {
        listThumb     :
          [
            'scale', {
              shortest: 160
            }
            'crop', {
              width   : 160
              height  : 80
            }
          ]
        appThumb      :
          [
            'scale', {
              shortest: 90
            }
            'crop', {
              width   : 90
              height  : 90
            }
          ]
      }
      title           : "Drop a logo of the app here..."

    screenshotsField = forms.Visuals.fields.screenshots
    screenshotsField.addSubView thumbUploader = new KDImageUploadView
      limit           : 10
      preview         : "thumbs"
      extensions      : null
      fileMaxSize     : 512
      totalMaxSize    : 4096
      fieldName       : "screenshots"
      convertToBlob   : yes
      actions         : {
        screenshot    :
          [
            'scale', {
              shortest: 768
            }
            'crop', {
              width   : 1024
              height  : 768
            }
          ]
        thumb         :
          [
            'scale', {
              shortest: 96
            }
            'crop', {
              width   : 96
              height  : 96
            }
          ]
      }
      title           : "Drop some screenshots here..."

  createAppSummary:(modal, pane)->
    modal.preview.destroy() if modal.preview
    formData = modal.modalTabs.getFinalData()
    log formData
    pane.form.addSubView (modal.preview = new AppPreSubmitPreview {},formData),null,yes
