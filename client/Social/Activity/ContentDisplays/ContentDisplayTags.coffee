class ContentDisplayTags extends KDView

  tags : [ "linux", "ubuntu", "gentoo", "arch", "debian", "distro", "macosx", "windows" ]

  viewAppended: ->
    @setData @tags #get real tags here with bongo
    data = @getData()

    @setPartial @partial data

  partial: (data)->
    partial = ""
    max = utils.getRandomNumber(11)
    for tag,index in data
      if index < max
        partial += "<span class='tag'>#{tag}</span>"
        # partial += "<span class='tag' style='background-color:#{utils.getRandomRGB()};'>#{tag}</span>"
    partial
