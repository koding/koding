kd = require 'kd'

module.exports = class SidebarStacksNotConfiguredPopup extends kd.ModalView

  constructor: (options = {}, data) ->

    options.width    = 610
    options.height   = 400
    options.cssClass = 'activity-modal sidebar-info-modal stacks-not-configured'
    options.overlay  = yes
    options.position =
      left           : 258
      top            : 60

    super options, data

    @createArrow()
    @createElements()


  createArrow: ->

    arrow = new kd.CustomHTMLView
      cssClass  : 'modal-arrow'
      position  : top : 20

    @addSubView arrow, ''


  createElements: ->

    @addSubView new kd.CustomHTMLView
      partial: """
        <div class="artboard"></div>
        <h2>Let's create your environment stack!</h2>
        <p>
          Before you start with your team page, we first need to setup your
          environment for your users to get their machines when they join!
        </p>
      """

    @addSubView new kd.ButtonView
      title     : 'LET\'S DO IT'
      cssClass  : 'solid green medium close'
      iconClass : 'check'
      callback  : -> kd.singletons.router.handleRoute '/Admin/Stacks'
