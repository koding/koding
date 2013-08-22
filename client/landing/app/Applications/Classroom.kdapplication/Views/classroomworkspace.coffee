class ClassroomWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    panelOptions    = data.config.panel
    config          = @extendOptions panelOptions
    config.delegate = options.delegate # TODO: fatihacet - it's a quick hack, we neeed to merge all other options.

    @addDefaultButtons panelOptions

    super config, data

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
      callback   : => @bound "showChapterList"

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

    router = KD.getSingleton "router"
    {course, chapter} = KD.utils.parseQuery router.getCurrentPath().split('?')[1]
    {chapters}        = @getData().courseManifest

    if chapters.length > chapter
      router.handleQuery "?course=#{course}&chapter=#{++chapter}"

  showChapterList: ->

