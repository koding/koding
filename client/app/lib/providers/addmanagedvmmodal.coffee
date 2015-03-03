kd = require 'kd'
KDView = kd.View
KDModalView = kd.ModalView
KDLoaderView = kd.LoaderView

class AddManagedVMModal extends KDModalView

  view             =
    header         : (title) -> new KDView
      partial      : title
      cssClass     : 'view-header'

    code           : (code) -> new KDView
      partial      : code
      cssClass     : 'view-code'

    waiting        : (title) ->

      container    = new KDView
        cssClass   : 'view-waiting'

      container.addSubView new KDLoaderView
        showLoader : yes
        size       :
          width    : 20
          height   : 20

      container.addSubView new KDView
        partial    : title
        cssClass   : 'title'

      return container

    list           : (data) ->

      new KDView partial: data

  addFollowingsTo = (parent, views)->

    map = {}
    for own key, value of views
      value = [value]  unless Array.isArray value
      parent.addSubView map[key] = view[key] value...

    return map


  States = { 'Initial', 'ListKites', 'FailedToConnect' }


  INSTALL_INSTRUCTIONS = """
    $ curl https://kd.io/kites/klient/latest | bash - </br>
    # Enter your koding.com credentials when asked for
  """

  constructor: (options = {}, data) ->

    options   =
      title   : 'Add your own VM'
      width   : 640

    super options, data

    @addSubView @container = new KDView

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
