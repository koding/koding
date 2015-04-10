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

    @iconWrapper.addSubView wrapper = new KDCustomHTMLView
      cssClass : "spec #{kd.utils.slugify(title).toLowerCase()}"

    wrapper.addSubView new KDCustomHTMLView
      tagName  : 'figure'
      partial  : '<span class="icon"></span>'

    wrapper.addSubView new KDCustomHTMLView
      cssClass : 'label'
      partial  : """
        <p>#{title}</p>
        <span>#{spec}</span>
      """


  createMoreView: ->

    @addSubView wrapper = new KDCustomHTMLView
      cssClass : 'need-more'
      partial  : '<p>Do you need more?</p>'

    wrapper.addSubView new KDButtonView
      title    : 'UPGRADE YOUR VM NOW'
      cssClass : 'solid green compact more'
      callback : =>
        kd.singletons.router.handleRoute '/Pricing'
        @emit 'ModalDestroyRequested'
