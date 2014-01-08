class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @readmeInput      = new KDInputViewWithPreview
      name            : "readme"
      cssClass        : "edit warn-on-unsaved-data readme-input"
      type            : "textarea"
      autogrow        : yes
      placeholder     : "This is your readme file."
      showHelperModal : yes
      preview         :
        showInitially : no

    group.fetchReadme (err, readme)=>
      if not err and readme?
        partial = readme.content or ""
        @readmeInput.setValue Encoder.htmlDecode partial

  makeEditable:->
    @readmeInput.setValue Encoder.htmlDecode @readme
    @readmeInput.show()

  getDefaultGroupReadme:(title)->
    defaultGroupReadme title

  save:->
    group         = @getData()
    previousValue = @readmeInput.getValue()
    @highlightCode()

    group.setReadme @readmeInput.getValue(), (err, readme)=>
      @readme = readme?.content or previousValue

  pistachio:-> "{{> @readmeInput}}"
