class AppScreenshotsView extends KDScrollView

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  putScreenshots:(screenshots)->
    app = @getData()
    log app,screenshots
    htmlStr = ""
    for set in app.screenshots
      htmlStr += "<figure><img class='screenshot' src='/images/uploads/#{set.screenshot}'></figure>"
    return htmlStr

  pistachio:->
    """
    <header><a href='#'>{{#(title)}} Screenshots</a></header>
    {{ @putScreenshots #(screenshots)}}
    """
