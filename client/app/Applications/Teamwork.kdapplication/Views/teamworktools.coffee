class TeamworkTools extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-share-modal"

    super options, data

    {@modal, @panel, @workspace, @twApp} = @getOptions()

    @createElements()

  createElements: ->
    @teamUpHeader  = new KDCustomHTMLView
      cssClass     : "header"
      partial      : """
        <span class="icon"></span>
        <h3 class="text">Team Up</h3>
        <p class="desc">I want to code together right now, on my VM</p>
      """
      click        : =>
        if @hasTeamUpElements
          @teamUpPlaceholder.destroySubViews()
          @unsetClass "active"
          @teamUpHeader.unsetClass "active"
          @hasTeamUpElements = no
        else
          @setClass "active"
          @teamUpHeader.setClass "active"
          @createTeamupElements()
          @hasTeamUpElements = yes

    @shareHeader   = new KDCustomHTMLView
      cssClass     : "header"
      partial      : """
        <span class="icon"></span>
        <h3 class="text">Export and share</h3>
        <p class="desc">Select a folder to export and share the link with your friends.</p>
      """
      click        : =>
        if @hasShareElements
          @sharePlaceholder.destroySubViews()
          @unsetClass "active"
          @shareHeader.unsetClass "active"
          @hasShareElements = no
        else
          @setClass "active"
          @shareHeader.setClass "active"
          @createShareElements()
          @hasShareElements = yes

    @teamUpPlaceholder = new KDCustomHTMLView cssClass: "content"
    @sharePlaceholder  = new KDCustomHTMLView cssClass: "content export"

  createTeamupElements: ->
    @teamUpPlaceholder.addSubView new KDCustomHTMLView
      tagName      : "p"
      cssClass     : "option"
      partial      : "Copy and send your session key or full URL to your friends"

    @keyInput      = new KDInputView
      cssClass     : "teamwork-modal-input key"
      defaultValue : @workspace.sessionKey
      attributes   :
        readonly   : "readonly"
      click        : => @keyInput.getDomElement().select()

    @urlInput      = new KDInputView
      cssClass     : "teamwork-modal-input url"
      defaultValue : "#{document.location.href}?sessionKey=#{@workspace.sessionKey}"
      attributes   :
        readonly   : "readonly"
      click        : => @urlInput.getDomElement().select()

    @teamUpPlaceholder.addSubView @keyInput
    @teamUpPlaceholder.addSubView @urlInput

    @teamUpPlaceholder.addSubView new KDCustomHTMLView
      tagName      : "p"
      cssClass     : "option"
      partial      : "Invite your Koding friends via their username"

    # TODO: it would be better to refactor userlist class bc some options are not required anymore.
    @inviteView    = new CollaborativeWorkspaceUserList
      workspaceRef : @workspace.workspaceRef
      sessionKey   : @workspace.sessionKey
      container    : this
      delegate     : this

    @teamUpPlaceholder.addSubView @inviteView
    @hasTeamUpContent = yes

  createShareElements: ->
    finderController   = new NFinderController
      nodeIdPath       : "path"
      nodeParentIdPath : "parentPath"
      foldersOnly      : yes
      contextMenu      : no
      loadFilesOnInit  : yes

    finder = finderController.getView()
    finderController.reset()
    finder.setHeight 150

    @sharePlaceholder.addSubView finder
    @sharePlaceholder.addSubView exportButton = new KDButtonView
      cssClass : "tw-export-button"
      title    : "Click to start export"

  export: ->
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

  pistachio: ->
    """
      {{> @teamUpHeader}}
      {{> @teamUpPlaceholder}}
      {{> @shareHeader}}
      {{> @sharePlaceholder}}
    """
