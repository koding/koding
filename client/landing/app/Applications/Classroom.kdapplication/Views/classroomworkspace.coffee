class ClassroomWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    panelOptions = data.config.panel

    @addDefaultButtons panelOptions

    config = @extendOptions panelOptions
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
    new KDModalView
      overlay      : yes
      title        : "Yay! Passed this chapter"
      cssClass     : "modal-with-text"
      content      : "<p>You have been passed this chapter. You have 3 more to go! Keep up the good work.</p>"
      buttons      :
        Next       :
          title    : "Next Chapter"
          cssClass : "modal-clean-green"
          callback : @bound "goToNextChapter"

  goToNextChapter: ->
    @destroy()
    @parent.addSubView new KDView
      partial : "dhehah"