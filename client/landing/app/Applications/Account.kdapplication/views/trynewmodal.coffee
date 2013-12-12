class TryNewModal extends KDModalView

  constructor: (options = {}, data) ->
    options.cssClass       = "trynew-modal"
    options.width          = 600
    options.overlay       ?= yes
    super options, data

  @switchToNew = ->
    $.cookie 'kdproxy-preferred-domain', 'newkoding'
    KD.whoami().modify preferredKDProxyDomain: 'newkoding', (err)->
      location.reload true

  viewAppended:->
    @unsetClass 'kdmodal'

    @addSubView new KDCustomHTMLView
      partial : """

        <h2>
          New Koding is here!
        </h2>

        <p>
          We’ve released a new version of Koding and we’d love for you to
          try it out. Here’s what’s new:
        </p>

        <div class='feature'>
          <img src="/images/icon_ui.png" />
          <p>A beautiful new UI</p>
        </div>

        <div class='feature'>
          <img src="/images/icon_rocket_new.png" />
          <p>Smoother Experience</p>
        </div>

        <div class='feature'>
          <img src="/images/icon_social.png" />
          <p>Intuitive Social Feed</p>
        </div>

      """

    @addSubView new KDCustomHTMLView
      partial  : 'Try the new Koding!'
      cssClass : 'button'
      click    : TryNewModal.switchToNew

    @addSubView new KDCustomHTMLView
      partial  : """

        <hr />

        <div class='warning'>
          <img src="/images/icon_warning.png" />
          <p>It’s still in beta, so you might find some bugs.</p>
          <p>Please report them in a status update tagged as </i>#bug</i>.</p>
        </div>

      """