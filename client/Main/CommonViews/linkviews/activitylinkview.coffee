class ActivityLinkView extends JView
  constructor:(options = {}, data)->
    options.tagName or= 'a'
    super options, data

  destroy:->
    super
    KD.getSingleton('linkController').unregisterLink this

  formatContent: (str = "") ->
    str = Encoder.htmlEncode str
    str = @utils.expandTokens str, @getData()
    return  str

  pistachio: ->
    {body, slug, group} = @getData()
    groupPath = if group is "koding" then "" else "/#{group}"
    """
    <a href="#{groupPath}/Activity/Post/#{slug}">{{@formatContent #(body)}}</a>
    """
