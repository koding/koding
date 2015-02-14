kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
globals = require 'globals'
defaultSlug = require 'app/util/defaultSlug'
JView = require 'app/jview'


module.exports = class NoMachinesFoundWidget extends JView

  constructor:->
    super cssClass : 'no-vm-found-widget'

    @loader = new KDLoaderView
      size          : width : 20
      loaderOptions :
        speed       : 0.7
        FPS         : 24

    @warning = new KDCustomHTMLView
      partial : "There is no attached VM"

  pistachio:->
    """
    {{> @loader}}
    {{> @warning}}
    """

  showMessage:(message)->
    message or= """There is no VM attached to filetree, you can
                   attach or create one from environment menu below."""

    @warning.updatePartial message
    @warning.show()

    @loader.hide()

  show:->
    @setClass 'visible'
    @warning.hide()
    @loader.show()

    if kd.getSingleton("groupsController").getGroupSlug() is defaultSlug
      @showMessage()

    # Not sure about it I guess only owners can create GroupVM?
    else if ("admin" in globals.config.roles) or ("owner" in globals.config.roles)
      group = kd.getSingleton("groupsController").getCurrentGroup()
      group.checkPayment (err, payments)=>
        kd.warn err  if err
        if payments.length is 0
          @showMessage """There is no VM attached for this group, you can
                          attach one or you can <b>pay</b> and create
                          a new one from environment menu below."""
        else
          @showMessage """There is no VM attached for this group, you can
                          attach one or you can create a new one from
                          environment menu below."""

    else
      @showMessage """There is no VM for this group or not attached to
                      filetree yet, you can attach one from environment
                      menu below."""

  hide:->
    @unsetClass 'visible'
    @loader.hide()
