class Pane extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry 'pane', options.cssClass

    super options, data

    @hash = options.hash or KD.utils.generatePassword 64, no


  setFocus: (state) ->


module.exports = Pane
