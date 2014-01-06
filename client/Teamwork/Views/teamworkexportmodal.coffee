class TeamworkExportModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-export-modal confirmation-modal"
    options.title    = "Lorem Ipsum Dolor Sit Amet"
    options.content  = "<p>You are about to export your #{data.path}</p>"
    options.overlay  = yes
    options.width    = 655
    options.buttons  =
      Next           :
        title        : "Next"
        iconClass    : "tw-next-button"
        icon         : yes
        callback     : -> new TeamworkExporterModal {}, data

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass : "tw-share-warning"
      partial  : """
        <span class="warning"></span>
        <p>PS: Be warned, this kind of sharing is gonna make your project kinda public so keep that in mind, be caraful, haters gonna hate.</p>
      """

