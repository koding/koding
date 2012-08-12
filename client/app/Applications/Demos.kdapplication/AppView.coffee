class DemosMainView extends KDScrollView
  
  viewAppended:()-> 
    
    # foo = new KDView
    #       cssClass : "bar"
    #     @addSubView foo
    #     foo.$().css "background-color" : "pink"
    
    @addSubView form = new KDFormView
      callback : -> 
        log arguments, "form submitted"
        new KDNotificationView
          title : "something"
    
    form.addSubView input = new KDInputView
     name              : "kk"
     validate          :
       rules           :
         required      : yes
         # maxLength     : 20
         #          minLength     : 10
         #          rangeLength   : [8,25]
         #          email         : yes
         #          creditCard    : yes
       messages        : 
         required      : "test"