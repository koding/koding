class DemosMainView extends KDScrollView
  
  viewAppended:()-> 
    
    @addSubView form = new KDFormView
      callback : -> 
        log arguments, "form submitted"

    form.addSubView new KDInputView
      name              : "kk"
      validate          :
        rules           :
          required      : yes
          maxLength     : 20
          minLength     : 10
          rangeLength   : [10,20]
          email         : yes
          creditCard    : yes


