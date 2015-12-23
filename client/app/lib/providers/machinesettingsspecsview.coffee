kd               = require 'kd'
KDView           = kd.View
KDButtonView     = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class MachineSettingsSpecsView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    { jMachine } = @getData()
    size = jMachine.meta?.storage_size
    type = jMachine.meta?.instance_type ? 't2.micro'
    ram  = {
      't2.nano'   : '512M'
      't2.micro'  : '1GB'
      't2.medium' : '4GB'
    }[type] ? '1GB'

    disk = if size? then "#{size}GB" else 'N/A'
    cpu  = '1x'

    @addSubView @iconWrapper = new KDCustomHTMLView cssClass: 'icons'

    @createIcon 'RAM',   ram
    @createIcon 'DISK',  disk
    @createIcon 'CORES', cpu

    kd.singletons.paymentController.subscriptions (err, subscription) =>

      if err
        @createMoreView()
        return showError err

      @createMoreView()  unless subscription.planTitle is 'professional'


  createIcon: (title, spec) ->

    @iconWrapper.addSubView new KDCustomHTMLView
      cssClass : "big-icon #{kd.utils.slugify(title).toLowerCase()}"
      partial  : """
        <figure>
          <span class="icon"></span>
        </figure>
        <div class="label">
          <p>#{title}</p>
          <span>#{spec}</span>
        </div>
      """


  createMoreView: ->

    @addSubView wrapper = new KDCustomHTMLView
      cssClass : 'need-more'
      partial  : '<p>Do you need more?</p>'

    wrapper.addSubView new KDButtonView
      title    : 'UPGRADE YOUR ACCOUNT'
      cssClass : 'solid green small more'
      callback : =>
        kd.singletons.router.handleRoute '/Pricing'
        @emit 'ModalDestroyRequested'
