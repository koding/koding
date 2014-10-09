class IDE.Pane extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry 'pane', options.cssClass

    super options, data

    @hash = KD.utils.generatePassword 64, no
