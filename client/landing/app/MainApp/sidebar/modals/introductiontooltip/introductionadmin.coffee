class IntroductionAdmin extends JView

  constructor: (options = {}, data) ->

    super options, data

    @currentTimestamp = Date.now()

    @buttonsContainer = new KDView
      cssClass : "introduction-admin-buttons"

    @buttonsContainer.addSubView @addButton = new KDButtonView
      cssClass : "editor-button"
      title    : "Add New Introduction Group"
      callback : => @showForm()

    @container = new KDView
      cssClass : "introduction-admin-content"

    @container.addSubView @loader = new KDLoaderView
      size     :
        width  : 36

    @container.addSubView @notFoundText = new KDView
      cssClass : "introduction-not-found"
      partial  : "There is no introduction yet."
    @notFoundText.hide()

    @container.addSubView @introListContainer = new KDView

    @fetchData()

    @on "IntroductionItemDeleted", (snippet) =>
      @snippets.splice @snippets.indexOf(snippet), 1
      if @snippets.length is 0
        @introListContainer.hide()
        @notFoundText.show()

  reload: ->
    parentView = @getOptions().parentView
    parentView.addSubView new IntroductionAdmin { parentView }
    @destroy()

  fetchData: ->
    KD.remote.api.JIntroSnippet.fetchAll (err, snippets) =>
      @loader.hide()
      @snippets = snippets
      return @notFoundText.show() if snippets.length is 0

      @introListContainer.addSubView new KDView
        cssClass : "admin-introduction-item admin-introduction-header"
        partial  : """
          <div class="cell name">Title</div>
          <div class="cell mini">Count</div>
          <div class="cell mini">In Use</div>
          <div class="cell mini">Overlay</div>
          <div class="cell mini">Visibility</div>
        """

      for snippet in snippets
        @introListContainer.addSubView new IntroductionItem
          delegate: @
        ,snippet

  showForm: (type = "Group", data = @getData(), actionType = "Insert", addingToAGroup = no) ->
    @buttonsContainer.hide()
    @container.hide()
    @addSubView @form = new IntroductionAdminForm {
      type
      actionType
      addingToAGroup
      delegate: @
    }
    , data

    @form.on "IntroductionFormNeedsReload", => @reload()

  viewAppended: ->
    super
    @loader.show()

  pistachio: ->
    """
      {{> @buttonsContainer}}
      {{> @container}}
    """

