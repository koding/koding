class DemosMainView extends KDScrollView
  
  viewAppended:()-> 
    
    @addSubView form = new KDFormView
      callback : -> 
        log arguments, "form submitted"

    form.addSubView new KDInputView
      name          : "kk"
      validate      :
        rules       :
          maxLength : 20
          minLength : 10
        messages    :
          maxLength : 'sidir it'
          minLength : 'itooluit'


