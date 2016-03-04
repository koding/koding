kd = require 'kd'
$  = require 'jquery'

module.exports = helpers =

  makePopupButton: (view, popup) ->

    skipNextClick = no
    popupIsHidden = no

    view.on 'click', (event) ->

      kd.utils.stopDOMEvent event
      { mainView } = kd.singletons

      if mainView.hasClass('hover') or mainView.isSidebarCollapsed
        mainView.resetSidebar()

      return skipNextClick = no  if skipNextClick

      popup.show()
      popupIsHidden = false

      popup.once 'AvatarPopupShouldBeHidden', (event) ->
        popupIsHidden = yes

      popup.once 'ReceivedClickElsewhere', (event) =>
        skipNextClick = if popupIsHidden
        then no
        else helpers.containsOrEqual view.getElement(), event.target

        popupIsHidden = no
        popup.hide()


  containsOrEqual: (element1, element2) ->

    return element1 is element2 or $.contains element1, element2
