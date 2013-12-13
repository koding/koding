class ClassroomWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    panelOptions      = data.config.panel
    config            = @putOptionsToConfig panelOptions
    config.delegate   = options.delegate # TODO: fatihacet - it's a quick hack, we neeed to merge all other options.

    @addDefaultButtons panelOptions

    super config, data

    @chapterRef = @workspaceRef.child "chapter"

    @on "AllPanesAddedToPanel", =>
      @createChapterList()
      @createChapterDescription()

    @on "WorkspaceSyncedWithRemote", =>
      KD.utils.wait 500, => # intentional to show slide in
        @animateContent @chapterDescription

  putOptionsToConfig: (options) ->
    config = {}
    config.name                = "Classroom"
    config.joinModalTitle      = "Join a coding session"
    config.joinModalContent    = "<p>Paste the session key that you received and start coding together.</p>"
    config.shareSessionKeyInfo = "<p>This is your session key, you can share this key with your friends to work together.</p>"
    config.firebaseInstance    = "tw-local"
    config.panels              = [options]
    config.enableChat          = yes

    return config

  addDefaultButtons: (options) ->
    options.buttons or= []
    options.buttons.unshift
      title      : "Submit Code"
      cssClass   : "cupid-green"
      loader     :
        color    : "#FFFFFF"
        diameter : 13
      callback   : (panel, workspace) =>
        button   = @getActivePanel().headerButtons["Submit Code"]
        button.showLoader()
        @validateChapter panel, workspace, (result) => button.hideLoader()
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

  validateChapter: (panel, workspace, callback) ->
    {config}   = @getData()
    if config.validate
      config.validate panel, workspace, (result) =>
        if result
          @handleChapterSuccess()
          config.onSuccess? panel, workspace
          callback yes
        else
          @handleChapterFailed()
          config.onFailed?  panel, workspace
          callback no
    else
      callback null

  handleChapterSuccess: ->
    data              = @getData()
    courseManifest    = data.courseManifest
    courseName        = courseManifest.name
    chapterTitle      = courseManifest.chapters[data.courseMeta.index - 1].title
    remainingChapters = courseManifest.chapters.length - data.courseMeta.index

    @getDelegate().emit "ChapterSucceed", { courseName, chapterTitle }

    if remainingChapters > 0
      title        = "Yay! You passed this chapter."
      content      = "You have been passed this chapter. You have #{remainingChapters} more to go! Keep up the good work."
      buttons      =
        Next       :
          title    : "Next Chapter"
          cssClass : "modal-clean-green"
          callback : =>
            @goToNextChapter modal, remainingChapters is 1
    else
      title        = "Well done!"
      content      = "You have completed this course. You can go to courses to start another one."
      buttons      =
        Done       :
          title    : "Go to Courses"
          cssClass : "modal-clean-green"
          callback : => @goToCoursesView modal

    modal = new KDBlockingModalView {
      overlay      : yes
      cssClass     : "modal-with-text"
      content      : "<p>#{content}</p>"
      buttons
      title
    }

  handleChapterFailed: ->
    modal = new KDModalView
      overlay      : yes
      title        : "Oops! One more time."
      cssClass     : "modal-with-text"
      content      : "<p>It seems, it's not working. Never mind, try again.</p>"
      buttons      :
        Again      :
          title    : "Try again"
          cssClass : "modal-clean-gray"
          callback : => modal.destroy()

  goToNextChapter: (modal, nextChapterIsLastChapter) ->
    {nextChapterConfig} = @getDelegate()
    nextChapterLayout   = nextChapterConfig.panel
    @addDefaultButtons nextChapterLayout
    @getOptions().panels.push nextChapterLayout

    @next()
    data = @getData()
    data.config = nextChapterConfig
    data.courseMeta.index++

    unless nextChapterIsLastChapter
      delegate = @getDelegate()
      delegate.currentChapterIndex++
      delegate.fetchNextCourseConfig()

    modal.destroy()

  goToCoursesView: (modal) ->
    modal.destroy()  if modal
    KD.getSingleton("router").handleRoute "/Develop/Classroom"

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
