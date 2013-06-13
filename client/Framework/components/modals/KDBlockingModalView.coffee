class KDBlockingModalView extends KDModalView
  constructor:->
    super
    $(window).off "keydown.modal"

  putOverlay:->
    @$overlay = $ "<div/>",
      class : "kdoverlay"
    @$overlay.hide()
    @$overlay.appendTo "body"
    @$overlay.fadeIn 200

  setDomElement:(cssClass)->
    @domElement = $ """
        <div class='kdmodal #{cssClass}'>
          <div class='kdmodal-shadow'>
            <div class='kdmodal-inner'>
              <div class='kdmodal-title'></div>
              <div class='kdmodal-content'></div>
            </div>
          </div>
        </div>
      """

  click:(e)->