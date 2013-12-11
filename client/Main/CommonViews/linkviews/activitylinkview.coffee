class ActivityLinkView extends JView

  #subjectMap = ->
    #JNewStatusUpdate : "status update"

  constructor:(options = {}, data)->

    options.tagName or= 'a'
    super options, data

    {slug, group} = @getData()
    groupLink = if group is "koding" then "" else "/#{group}"

    {bongo_:{constructorName}, body} = @getData()
    #type = subjectMap()[constructorName]

    @slug = "#{groupLink}/Activity/#{slug}"  if slug
    @link =  "<a href=#{@slug}>#{body}</a>"

  destroy:->
    super
    KD.getSingleton('linkController').unregisterLink this

  pistachio: -> "#{@link}"
