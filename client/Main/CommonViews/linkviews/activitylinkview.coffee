class ActivityLinkView extends JView

  subjectMap = ->
    JStatusUpdate       : "status"

  constructor:(options = {}, data)->

    options.tagName or= 'a'
    super options, data

    {slug, group} = @getData()
    groupLink = if group is "koding" then "" else "/#{group}"

    {bongo_:{constructorName}} = @getData()
    type = subjectMap()[constructorName]

    @slug = "#{groupLink}/Activity/#{slug}"  if slug
    @link =  "<a href=#{@slug}>#{type}</a>"

  destroy:->
    super
    KD.getSingleton('linkController').unregisterLink this

  pistachio: -> "#{@link}"