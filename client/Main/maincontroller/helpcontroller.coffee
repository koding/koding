class HelpController extends KDController

  name    = "HelpController"
  version = "0.1"

  KD.registerAppClass this, {name, version, background: yes}

  showHelp:(delegate)->

    @_modal?.destroy?()
    @_modal = new HelpModal {delegate}


class HelpPage extends KDSlidePageView

  constructor:(data)->
    options = cssClass: 'help-page'
    super options, data

  pistachio:->
    """
      {h3{#(title)}}
      <div class='content'>
        {span{#(content)}}
        <img src="#{@getData().image}"/>
      </div>
    """

class HelpModal extends AnimatedModalView

  constructor:(options, data)->

    options.cssClass     = 'kdhelp-modal'
    options.overlay      = yes
    options.overlayClick = yes

    super options, data

    @slider = new KDSlideShowView
      cssClass     : 'help-content'
      direction    : 'leftToRight'
      touchEnabled : no

    @addSubView new KDCustomHTMLView
      partial : """
        <h2>Welcome on board!</h2>
        <p>
          You're now part of something exciting here ... FIXME
        </p>
      """

    @addSubView buttonContainer = new KDCustomHTMLView
      cssClass : "button-container"

    buttonContainer.addSubView new InlineHelpButton
      cssClass : "activity"
      callback : => @slider.jump 0
    buttonContainer.addSubView new InlineHelpButton
      cssClass : "teamwork"
      callback : => @slider.jump 1
    buttonContainer.addSubView new InlineHelpButton
      cssClass : "terminal"
      callback : => @slider.jump 2
    buttonContainer.addSubView new InlineHelpButton
      cssClass : "editor"
      callback : => @slider.jump 3
    buttonContainer.addSubView new InlineHelpButton
      cssClass : "apps"
      callback : => @slider.jump 4

    @addSubView @slider

    @slider.addPage new HelpPage
      title: "Activity"
      content: """Share with the community, learn from the experts or
                  help the ones who has yet to start coding. Socialize
                  with like minded people and have fun."""

    @slider.addPage new HelpPage
      title: "Teamwork"
      content: """Teamwork collaborative ..."""
    @slider.addPage new HelpPage
      title: "Terminal"
      content: """Terminal whoohooo"""
    @slider.addPage new HelpPage
      title: "Editor"
      content: """Text editor rulez."""
    @slider.addPage new HelpPage
      title: "Apps"
      content: """Applicashyons."""

    @addSubView new KDCustomHTMLView
      partial  : """

        <hr />

        <div class='warning'>
          <img src="/a/images/icon_warning.png" />
          <p>It’s still in beta, so you might find some bugs.</p>
          <p>Please report them in a status update tagged as </i>#bug</i>.</p>
        </div>

      """

class InlineHelpButton extends KDButtonView

  constructor:(options={}, data)->
    options.iconOnly = yes
    options.cssClass = KD.utils.curry 'inline-help-button', options.cssClass
    super options, data
