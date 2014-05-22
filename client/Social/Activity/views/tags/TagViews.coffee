class TagGroup extends KDCustomHTMLView

  JView.mixin @prototype
  #intended as a superclass for tag groups - note no pistachio, so this will not work on its own
  constructor:(options, data)->
    options = $.extend
      cssClass      : 'tag-group'
    , options
    super options, data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  fetchTags:(stringTags, callback)->
    @_fetchTags 'some', stringTags, callback

  _fetchTags:(method, stringTags, callback)->
    if stringTags.length > 0
      KD.remote.api.JTag[method]
        title     :
          $in     : stringTags
      ,
        sort      :
          title   : 1
      , (err,tags)=>
        unless err and not tags
          callback null, tags
        else
          callback err
          warn "there was a problem fetching default tags!", err, tags
    else
      warn "no tag info was given!"

class SkillTagGroup extends TagGroup
  constructor:(options, data)->
    super options, data

    {@skillTags} = @getData() or []
    name = KD.utils.getFullnameFromAccount @getData(), yes
    @noTags = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "noskilltags"
      partial   : "#{name} hasn't entered any skills yet."

    controller = new KDListViewController
      view            : new KDListView
        itemClass     : TagCloudListItemView
        cssClass      : "skilltag-cloud"
        delegate      : @

    controller.listView.on 'TagWasClicked', =>
      @emit 'TagWasClicked'

    @listViewWrapper = controller.getView()

    unless @skillTags.length is 0 or @skillTags[0] is "No Tags"
      @fetchTags @skillTags, (err, tags)=>
        unless err
          controller.instantiateListItems tags

    @getData().watch "skillTags", -> controller.replaceAllItems @skillTags

  fetchTags:(stringTags, callback)->
    @_fetchTags 'fetchSkillTags', stringTags, callback

  pistachio:->
    if not @skillTags.length or @skillTags[0] is "No Tags"
      '{{> @noTags}}'
    else
      '{{> @listViewWrapper}}'

class TagCloudListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options, data)->
    options = $.extend
      tagName     : "a"
      attributes  :
        href      : "#"
    , options
    super options, data
    @setClass "ttag"
    @unsetClass "kdview"
    @unsetClass "kdlistitemview"
    @unsetClass "kdlistitemview-default"

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    super "{{#(title)}}"

  click:(e)->
    e?.preventDefault()
    e?.stopPropagation()
    @openTag @getData()

  openTag:(tag)->
    {entryPoint} = KD.config
    KD.getSingleton('router').handleRoute "/Topics/#{tag.slug}", {state:tag, entryPoint}

#  click:(event)->
#    event?.stopPropagation()
#    event?.preventDefault()
#    @getDelegate().emit 'TagWasClicked'
#    @emit 'LinkClicked'