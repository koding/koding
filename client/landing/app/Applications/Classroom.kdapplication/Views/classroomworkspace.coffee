class ClassroomWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    panelOptions      = data.config.panel
    config            = @extendOptions panelOptions
    config.delegate   = options.delegate # TODO: fatihacet - it's a quick hack, we neeed to merge all other options.

    @addDefaultButtons panelOptions

    super config, data

    @on "AllPanesAddedToPanel", =>
      @createChapterList()
      @createChapterDescription()

    @on "WorkspaceSyncedWithRemote", =>
      KD.utils.wait 500, => # intentional to show slide in
        @animateContent @chapterDescription

  extendOptions: (options) ->
    config = {}
    config.joinModalTitle      = "Join a coding session"
    config.joinModalContent    = "<p>Paste the session key that you received and start coding together.</p>"
    config.shareSessionKeyInfo = "<p>This is your session key, you can share this key with your friends to work together.</p>"
    config.firebaseInstance    = "teamwork-local"
    config.panels              = [options]

    return config

  addDefaultButtons: (options) ->
    options.buttons or= []
    options.buttons.unshift
      title      : "Submit Code"
      cssClass   : "cupid-green"
      callback   : (panel, workspace) =>
        @validateChapter panel, workspace
    ,
      title      : "Join"
      cssClass   : "cupid-green join-button"
      callback   : (panel, workspace) =>
        workspace.showJoinModal()
    ,
      itemClass  : KDView
      cssClass   : "chapters"
      tooltip    :
        title    : "Show Chapters"
      click      : => @animateContent @chapterList
    ,
      itemClass  : KDView
      cssClass   : "information"
      tooltip    :
        title    : "Show Chapter information"
      click      : => @animateContent @chapterDescription

  validateChapter: (panel, workspace) ->
    {config}   = @getData()
    try
      result = config.validation? panel, workspace
      if result
        @handleChapterSuccess()
        config.onSuccess? panel, workspace
      else
        config.onFailed?  panel, workspace

  handleChapterSuccess: ->
    data           = @getData()
    courseManifest = data.courseManifest
    courseName     = courseManifest.name
    chapterTitle   = courseManifest.chapters[data.courseMeta.index - 1].title

    @getDelegate().emit "ChapterSucceed", { courseName, chapterTitle }

    modal = new KDModalView
      overlay      : yes
      title        : "Yay! Passed this chapter."
      cssClass     : "modal-with-text"
      content      : "<p>You have been passed this chapter. You have 3 more to go! Keep up the good work.</p>"
      buttons      :
        Next       :
          title    : "Next Chapter"
          cssClass : "modal-clean-green"
          callback : => @goToNextChapter modal

  goToNextChapter: (modal) ->
    parent = @parent
    modal.destroy()
    parent.destroySubViews()

    {index, name} = @getData().courseMeta
    {chapters}    = @getData().courseManifest
    if chapters.length > index
      KD.getSingleton("router").handleQuery "?course=#{name}&chapter=#{++index}"

  createChapterList: ->
    @addSubView @chapterList = new ClassroomChapterList {}, @getData().courseManifest

  createChapterDescription: ->
    @addSubView @chapterDescription = new KDView
      cssClass : "chapter-description"
      partial  : """
        <h2 class="chapter-index">Chapter #{@getData().courseMeta.index}</h2>
        #{@getData().config.panel.hint}
      """

  animateContent: (container) ->
    container.toggleClass "active"
    if container.hasClass "active"
      KD.getSingleton("windowController").addLayer container
      container.once "ReceivedClickElsewhere", ->
        container.toggleClass "active"