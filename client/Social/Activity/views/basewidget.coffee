class ActivityBaseWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'activity-widget', options.cssClass

    super options, data

    @readLessLink       = new CustomLinkView
      title             : 'hide info...'
      cssClass          : 'read-more-link hidden'
      click             : =>
        @unsetClass 'expand'
        @readMoreLink.show()
        @readLessLink.hide()

    @readMoreLink       = new CustomLinkView
      title             : 'read more...'
      cssClass          : 'read-more-link'
      click             : =>
        @setClass 'expand'
        @readMoreLink.hide()
        @readLessLink.show()
