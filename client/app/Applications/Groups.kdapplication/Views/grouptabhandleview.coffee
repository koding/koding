class GroupTabHandleView extends KDTabHandleView

  constructor:(options, data)->
    options.cssClass = @utils.curryCssClass 'grouptabhandle', options.cssClass
    super
    @isDirty = no

  viewAppended:->
    @currentCount = 0
    @newCount = new KDCustomHTMLView tagName: 'span'

    JView::viewAppended.call this

  pistachio:->
    "#{@getOptions().title} {.new{> @newCount}}"

  markDirty:(@isDirty=yes)->
    if @isDirty
      @setClass 'dirty'  unless @currentCount++
      @newCount.updatePartial @currentCount
    else
      @unsetClass 'dirty'
      @newCount.updatePartial ''