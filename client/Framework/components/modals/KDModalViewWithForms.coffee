class KDModalViewWithForms extends KDModalView
  constructor:(options,data)->
    @modalButtons = []
    super options,data
    @addInnerSubView @modalTabs = new KDTabViewWithForms options.tabs


# new KDModalViewWithForms
#     title     : "with tabs and forms"
#     content   : ""
#     overlay   : yes
#     width     : 500
#     height    : "auto"
#     cssClass  : "new-kdmodal"
#     tabs                    :
#       navigable          : yes
#       callback              : (formOutput)-> log formOutput,"All Forms ::::::"
#       forms                 :
#         "My first form"     :
#           buttons           :
#             Next            :
#               title         : "Next"
#               style         : "modal-clean-gray"
#               type          : "submit"
#           # callback          : (formOutput)-> log formOutput,"Form 1 ::::::"
#           fields            :
#             Hiko            :
#               label         : "Title:"
#               type          : "text"
#               name          : "hiko"
#               placeholder   : "give a name to your topic..."
#               validate      :
#                 rules       :
#                   required  : yes
#                 messages    :
#                   required  : "topic name is required!"
#             Zikko           :          
#               label         : "Zikkko"
#               type          : "textarea"
#               name          : "zikko"
#               placeholder   : "give something else to your topic..."
#               nextElement   :
#                 lulu        :
#                   type        : "text"
#                   name        : "lulu"
#                   placeholder : "lulu..."
#         "My Second Form"    :
#           buttons           :  
#             Submit          :
#               title         : "Submit"
#               style         : "modal-clean-gray"
#               type          : "submit"
#             Reset           :
#               title         : "Reset"
#               style         : "modal-clean-red"
#               type          : "reset"
#           # callback          : (formOutput)-> log formOutput,"Form 2 ::::::"
#           fields            :  
#             Hoho            :           
#               label         : "Hoho:"
#               type          : "text"
#               name          : "title"
#               placeholder   : "give a gogo..."
#               validate      :
#                 rules       :
#                   required  : yes
#                 messages    :
#                   required  : "topic name is required!"