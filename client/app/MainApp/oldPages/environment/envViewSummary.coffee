class EnvironmentViewSummary extends KDView
  viewAppended:->
    @setHeight "auto"
    @addSubView subHeader = new KDHeaderView type:"small",title:"Server"
    data = @getData()
    @setPartial @partial data
    @putTags data.tags
    @putMeta data
  
  putTags:(tags)->
    for tag in tags
      @addSubView (new KDCustomHTMLView tagName : "span", cssClass : "color1", partial : tag),"p.langtags"

  putMeta:(data)->
    # put load
    for load in data.load
      @addSubView (new KDCustomHTMLView tagName : "span", partial : load, cssClass : "color1"),"p.meta-load"
    # put uptime
    @addSubView (new KDCustomHTMLView tagName : "span", partial : data.uptime),"p.meta-uptime"
    

  partial:(data)->
    """
      <div class='icon-wrapper'><span class='icon server'></span></div>
      <div class='content-wrapper'>
        <strong>#{data.title}</strong>
        <p class='langtags'></p>
        <p class='meta-load'>LOAD:</p>
        <p class='meta-uptime'>UPTIME:</p>
      </div>
    """
