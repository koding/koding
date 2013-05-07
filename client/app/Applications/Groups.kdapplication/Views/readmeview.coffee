class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @readmeView       = new KDView
    @readmeInput      = new KDInputViewWithPreview
      name            : "body"
      cssClass        : "edit warn-on-unsaved-data readme-input"
      type            : "textarea"
      autogrow        : yes
      placeholder     : "This is your readme file."
      showHelperModal : yes
      preview         :
        showInitially : no

    @readmeEditButton = new KDButtonView
      title           : 'Edit Readme'
      cssClass        : 'clean-gray readme-edit'
      callback        : =>
        @readmeInput.setValue Encoder.htmlDecode @readme
        @readmeView.hide()
        @showReadmeEditButtons()
        @readmeEditButton.hide()

    @readmeSaveButton = new KDButtonView
      title           : "Save Changes"
      cssClass        : 'clean-gray readme-save'
      loader          :
        color         : "#444444"
        diameter      : 12
      callback        : @bound "save"

    @readmeCancelLink = new CustomLinkView
      title           : 'Cancel'
      cssClass        : 'edit-cancel readme-cancel'
      click           : (event)=>
        event.preventDefault()
        @readmeView.show()
        @hideReadmeEditButtons()
        @readmeEditButton.show()

    @readmeInput.hide()
    @readmeEditButton.hide()
    @hideReadmeEditButtons()

  hideReadmeEditButtons:->
    @readmeInput.hide()
    @readmeSaveButton.hide()
    @readmeCancelLink.hide()

  showReadmeEditButtons:->
    @readmeInput.show()
    @readmeSaveButton.show()
    @readmeCancelLink.show()

  getDefaultGroupReadme:(title)->
    defaultGroupReadme title

  defaultGroupReadme = (title)->
    """
    <h1>Hello!</h1>
    <p>Welcome to the <strong>#{title}</strong> group on Koding.<p>
    <h2>Talk.</h2>
    <p>Looking for people who share your interest? You are in the right place. And you can discuss your ideas, questions and problems with them easily.</p>
    <h2>Share.</h2>
    <p>Here you will be able to find and share interesting content. Experts share their wisdom through links or tutorials, professionals answer the questions of those who want to learn.</p>
    <h2>Collaborate.</h2>
    <p>You will be able to share your code, thoughts and designs with like-minded enthusiasts, discussing and improving it with a community dedicated to improving each other's work.</p>
    <p>Go ahead, the members of <strong>#{title}</strong> are waiting for you.</p>
    """

  viewAppended:->
    group = @getData()
    group.fetchReadme (err, readme)=>
      if not err and readme?
        partial = readme.content or getDefaultGroupReadme group.title
        # group.canEditGroup (err, allowed)=>
        #   @readmeEditButton.show() if allowed
      else
        partialHTML =
          if err?.message then err.message
          else @getDefaultGroupReadme group.title

      group.canEditGroup (err, allowed)=>
        @readmeEditButton.show() if allowed

      #SA: is this line being used anywhere, this overrides the logic above
      #@readme = readme?.content or partial
      @readmeView.updatePartial partialHTML or @utils.applyMarkdown partial
      @highlightCode()
      JView::viewAppended.call @
      @emit "readmeReady"


  highlightCode:->
    @$(".has-markdown pre").each (i,element)=>
      hljs.highlightBlock element

  save:->
    group         = @getData()
    previousValue = @readmeInput.getValue()
    @readmeView.updatePartial @utils.applyMarkdown @readmeInput.getValue()
    @highlightCode()

    group.setReadme @readmeInput.getValue(), (err, readme)=>
      @readme = readme?.content or previousValue
      if err
        @readmeView.updatePartial previousValue
      @readmeSaveButton.hideLoader()
      @readmeView.show()
      @hideReadmeEditButtons()
      @readmeEditButton.show() unless err

  pistachio:->
    """
    <div class="button-bar">
      {{> @readmeEditButton}}
      {{> @readmeCancelLink}}
      {{> @readmeSaveButton}}
    </div>
    {{> @readmeInput}}
    <figure class="has-markdown">
      {{> @readmeView}}
    </figure>
    """
