kd               = require 'kd'
KDView           = kd.View
KDButtonView     = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class MachineSettingsSpecsView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    size = @getData().jMachine.meta?.storage_size
    disk = if size? then "#{size}GB" else 'N/A'
    ram  = '1GB'
    cpu  = '1x'

    @addSubView @iconWrapper = new KDCustomHTMLView cssClass: 'icons'

    @createIcon 'RAM',   ram
    @createIcon 'DISK',  disk
    @createIcon 'CORES', cpu

    @createMoreView()


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
      title    : 'UPGRADE YOUR VM NOW'
      cssClass : 'solid green small more'
      callback : =>
        kd.singletons.router.handleRoute '/Pricing'
        @emit 'ModalDestroyRequested'
