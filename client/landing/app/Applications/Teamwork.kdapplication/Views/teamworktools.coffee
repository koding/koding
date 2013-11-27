class TeamworkTools extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-share-modal"

    super options, data

    {modal, panel, workspace, twApp} = @getOptions()

    @sessionKeyInput = new KDInputView
      cssClass       : "teamwork-modal-input session-key"
      defaultValue   : @getOptions().workspace.sessionKey
      attributes     :
        readonly     : "readonly"
      click          : => @sessionKey.getDomElement().select()

    @exportButton    = new KDButtonView
      title          : "Click here to select a folder to export"
      icon           : yes
      iconClass      : "export"
      callback       : => @showFinder()

    @exportView      = new KDView
      cssClass       : "export-file-tree"

    @exportStartButton = new KDButtonView
      title          : "Select a folder and click here to export..."
      cssClass       : "clean-gray hidden exporter"
      callback       : =>
        return if @exporting

        [node]       = @finderController.treeController.selectedNodes
        unless node
          return new KD.NotificationView
            title    : "Please select a folder to save!"
            type     : "mini"
            cssClass : "error"
            duration : 4000

        vmController = KD.getSingleton "vmController"
        nodeData     = node.getData()
        fileName     = "#{nodeData.name}.zip"
        path         = FSHelper.plainPath nodeData.path
        notification = new KDNotificationView
          title      : "Exporting file..."
          type       : "mini"
          duration   : 30000
          container  : @finderContainer

        vmController.run "cd #{path}/.. ; zip -r #{fileName} #{nodeData.name}", (err, res) =>
          @exporting = yes
          return @updateNotification notification  if err

          file = FSHelper.createFileFromPath "#{nodeData.parentPath}/#{fileName}"
          file.fetchContents (err, contents) =>
            return @updateNotification notification  if err
            FSHelper.s3.upload fileName, btoa(contents), (err, res) =>
              return @updateNotification notification  if err
              vmController.run "rm -f #{path}.zip", (err, res) =>
              KD.utils.shortenUrl res, (shorten) =>
                @exporting = no
                notification.notificationSetTitle "Your content has been exported."
                notification.notificationSetTimer 4000
                notification.setClass "success"
                @getOptions().modal.destroy()
                @showUrlShareModal shorten
          , no

    @inviteView = new CollaborativeWorkspaceUserList {
      workspaceRef: workspace.workspaceRef
      sessionKey  : workspace.sessionKey
      container   : this
      delegate    : this
    }

  showUrlShareModal: (shortenUrl) ->
    modal          = new KDBlockingModalView
      title        : "Export done"
      cssClass     : "modal-with-text"
      overlay      : yes
      content      : "<p>Your content has been uploaded and it's ready to share.</p>"
      buttons      :
        Done       :
          title    : "Done"
          cssClass : "modal-clean-gray"
          callback : -> modal.destroy()

    modal.addSubView urlInput = new KDInputView
      cssClass       : "teamwork-url-share-input"
      defaultValue   : "#{location.origin}/Develop/Teamwork?import=#{shortenUrl}"
      attributes     :
        readonly     : "readonly"
      click          : => urlInput.getDomElement().select()

  showFinder: ->
    if @exportView.getSubViews().length is 0
      @finderContainer    = new KDView
      @finderController   = new NFinderController
        nodeIdPath        : "path"
        nodeParentIdPath  : "parentPath"
        foldersOnly       : yes
        contextMenu       : no
        loadFilesOnInit   : yes

      @finder = @finderController.getView()
      @finderController.reset()
      @finder.setHeight 320
      @finderContainer.addSubView @finder
      @finderContainer.addSubView @exportStartButton
      @exportView.addSubView @finderContainer

    @exportView.setClass "active"
    @exportButton.hide()
    @exportStartButton.show()
    KD.getSingleton("windowController").addLayer @finderContainer
    @finderContainer.on "ReceivedClickElsewhere", =>
      @exportStartButton.hide()
      @exportButton.show()
      @exportView.unsetClass "active"

  updateNotification: (notification) ->
    notification.notificationSetTitle "Something went wrong"
    notification.notificationSetTimer 4000
    notification.setClass "error"
    @exporting = no

  pistachio: ->
    """
      <div class="header active">
        <span class="icon"></span>
        <h3 class="text">Team Up</h3>
        <p class="desc">I want to code together right now, on my VM</p>
      </div>
      <div class="content">
        <p class="option">Copy and send your session key to friends</p>
        {{> @sessionKeyInput}}
        <p class="option">Invite your Koding friends via their username</p>
        {{> @inviteView}}
      </div>
      <div class="header">
        <span class="icon"></span>
        <h3 class="text">Export and share</h3>
        <p class="desc">Share your files with others.</p>
      </div>
      <div class="content">
        <p>Lorem Ipsum Dolor Sit Amet</p>
      </div>
    """
