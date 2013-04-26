class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @readmeView       = new KDView
    @readmeInput      = new KDInputViewWithPreview
      name            : "body"
      cssClass        : "edit warn-on-unsaved-data"
      type            : "textarea"
      autogrow        : yes
      placeholder     : "This is your readme file."
      showHelperModal : no

    @readmeEditButton = new KDButtonView
      title           : 'Edit the Readme'
      cssClass        : 'clean-gray'
      callback        : =>
        @readmeInput.setValue Encoder.htmlDecode @readme
        @readmeView.hide()
        @showReadmeEditButtons()
        @readmeEditButton.hide()

    @readmeSaveButton = new KDButtonView
      title           : "Save Changes"
      cssClass        : 'clean-gray'
      loader          :
        color         : "#444444"
        diameter      : 12
      callback        : @bound "save"

    @readmeCancelLink = new CustomLinkView
      title           : 'Cancel'
      cssClass        : 'edit-cancel'
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

  viewAppended:->
    group = @getData()
    group.fetchReadme (err, readme)=>
      unless err
        partial = readme?.content or "This group does not have any associated readme data yet."
        group.canEditGroup (err, allowed)=>
          @readmeEditButton.show() if allowed
      else
        partial = err.message or "Access denied! Please join the group."

      @readme = readme?.content or partial
      @readmeView.updatePartial @utils.applyMarkdown partial
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
