kd = require 'kd'

States = { 'Initial', 'ListKites', 'FailedToConnect' }

INSTALL_INSTRUCTIONS = """
  $ curl https://kd.io/kites/klient/latest | bash - </br>
  # Enter your koding.com credentials when asked for
"""

view             =

  header         : (title) -> new kd.View
    partial      : title
    cssClass     : 'view-header'

  code           : (code) -> new kd.View
    partial      : code
    cssClass     : 'view-code'

  waiting        : (title) ->

    container    = new kd.View
      cssClass   : 'view-waiting'

    container.addSubView new kd.LoaderView
      showLoader : yes
      size       :
        width    : 20
        height   : 20

    container.addSubView new kd.View
      partial    : title
      cssClass   : 'title'

    return container

  list           : (data) ->

    new kd.View partial: data


addFollowingsTo = (parent, views)->

  map = {}
  for own key, value of views
    value = [value]  unless Array.isArray value
    parent.addSubView map[key] = view[key] value...

  return map


module.exports = class AddManagedVMModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options    =
      title    : 'Add your own VM'
      width    : 640
      cssClass : 'managed-vm modal'

    super options, data

    @addSubView @container = new kd.View


  viewAppended: ->

    @switchTo States.Initial

    kd.utils.wait 13000, =>
      @switchTo States.ListKites, 'Kite data will be here'


  switchTo: (state, data)->

    @container.destroySubViews()

    switch state

      when States.Initial

        addFollowingsTo @container,
          header    : 'Instructions'
          code      : INSTALL_INSTRUCTIONS
          waiting   : 'Checking for new instances...'

      when States.ListKites

        addFollowingsTo @container,
          header    : 'Instructions'
          code      : INSTALL_INSTRUCTIONS
          list      : data
