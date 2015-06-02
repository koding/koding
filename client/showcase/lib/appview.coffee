ReactAppView = require 'app/react/reactappview'

###*
 * Bridge between KD and React. Finally. ~Umut
###
module.exports = class ShowcaseAppView extends ReactAppView

  constructor: (options = {}, data) ->

    options.cssClass = 'ShowcaseApp'

    super options, data


  showReactComponent: (args...) -> @setComponent args...



