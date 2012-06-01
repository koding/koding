class JHyperlink extends bongo.Model
  
  @share()
  
  @set
    schema    :
      url     : 
        type  : String
        url   : yes
      title   : String
      target  : 
        type  : String
        enum  : ["_blank", "_self"]
