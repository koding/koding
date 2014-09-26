class ActivityBaseWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'activity-widget', options.cssClass

    super options, data
