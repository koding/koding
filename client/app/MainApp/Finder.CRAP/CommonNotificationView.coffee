class CommonNotificationView extends KDNotificationView  
  constructor: (options) -> 
    defaults = 
      type      : 'growl'  
      duration  : 2500 

    options = $.extend defaults, options 
    super  

    if @getOptions().description 
      @listenTo  
        KDEventTypes: 'click'  
        listenedToInstance: @  
        callback: @showDescription

  showDescription: ->  
    modal = new KDModalView  
      title     : @getOptions().title  
      cssClass  : 'new-kdmodal' 
      height    : 'auto' 
      width     : 400 
      fx        : yes 
      # content: @getOptions().description  
      buttons:   
        Okay:   
          style     : "modal-clean-gray"  
          callback  : ()->  
            modal.destroy() 

    scrollView = new KDScrollView cssClass: 'modalformline' 

    label = new KDLabelView title: 'Error description:', cssClass: 'warning-headline' 
    scrollView.addSubView label 

    description = new KDCustomHTMLView tagName: 'p',cssClass: 'delete-file', partial: @getOptions().description 
    scrollView.addSubView description 

    modal.addSubView scrollView, '.kdmodal-content'
