class DomainRegisterModalFormView extends KDModalViewWithForms

  # created by: Erdinc
  
  actionState = "new"
  
  constructor:(options={}, data)->
    parentData = @getData()
  
    selectOptions = [{title: "Select your vm" , value :"null"}]
    radioOptions = [{ title : "I want to register one...", value : "new"}
                    { title : "i have a domain...",        value : "existing"}]
    formInfo = 
    """
      <div class="modalformline">Register your next awesome, incredible domain address!!!</div>
    """
    
    options = {      
      title                             : "Domain Registration"
      content                           : formInfo
      overlay                           : no
      width                             : 600
      height                            : "auto"
      cssClass                          : "domain-register-modal-view"
      tabs                              :
        navigable                       : no
        goToNextFormOnSubmit            : no
        forms                           :
          "Domain Address"              :
            callback                    : => @loadSearchDomainPane()
            buttons                     :
              Next                      :
                title                   : "Next"
                style                   : "modal-clean-gray"
                type                    : "submit"
                loader                  :
                  color                 : "#444444"
                  diameter              : 12
                  
            fields                      :
              DomainOption              :
                name                    : "DomainOption"
                itemClass               : KDInputRadioGroup
                cssClass                : "group-type"
                defaultValue            : "new"
                radios                  : radioOptions
                change                  : =>
                  actionState = @modalTabs.forms["Domain Address"].inputs.DomainOption.getValue()
                  
          "Find Your Domain"            :
            buttons                     : null
            fields                      : {}
          
          "Done"                        :
            buttons                     : null
            fields                      : {}
    }
    
    super options, data
    
    KD.remote.api.JVM.fetchVms (err, vms)=>
      selects = []
      for i, vmName of vms
        selects.push {
          title :"#{vmName}.kd.io"
          value:"#{vmName}.kd.io"
          }
           
      @emit "UserVMMenuReady", selects
      

    @on "DomainRegistered", (orderInfo) =>
      @modalTabs.forms["Connect"].buttons.Next.hideLoader()
      
      @modalTabs.forms["Done"].addSubView (
        new DomainRegistrationCompleteView {orderInfo : orderInfo}
        )
        
      @modalTabs.showPaneByIndex "3"
      
      
    @on "DomainForwarded", (orderInfo) =>
      @modalTabs.forms["Connect"].buttons.Next.hideLoader()
      
      @modalTabs.forms["Done"].addSubView (
        new DomainForwardingCompleteView {orderInfo : orderInfo}
        )
        
      @modalTabs.showPaneByIndex "3"
      
      
  loadSearchDomainPane:->
    @modalTabs.showPaneByIndex 1
    @setData {}
    
    
    if actionState is "new"
      
      @modalTabs.forms["Find Your Domain"].addSubView (
        new DomainSearchForm { 
          modalTabs  : @modalTabs
          parentData : @getData()
          }
        )
    else
      
      @modalTabs.forms["Find Your Domain"].addSubView (
        new DomainForwardForm {
          modalTabs  : @modalTabs
          parentData : @getData()
          }
        )
        
  saveDomainInformation:->
    {selectedDomain, newDomain} = @getData()
    
    if newDomain 
      VMToBind = @modalTabs.forms["Connect"].inputs.SelectVM.getValue()
      KD.remote.api.JDomain.registerNewDomain {domainAddress:selectedDomain, selectedVM : VMToBind}, (err, orderInfo)=>
        @emit "DomainRegistered", orderInfo
    else
      VMToBind = @modalTabs.forms["Connect"].inputs.SelectVM.getValue()
      KD.remote.api.JDomain.addNewDNSRecord {domainAddress:selectedDomain, selectedVM : VMToBind}, (err, orderInfo)=>
        @emit "DomainForwarded", orderInfo

    
class DomainSearchForm extends KDScrollView

  constructor:(options = {}, data)->
    super options,data
    
    {@modalTabs,parentData} = @getOptions()
    
    #TODO : change it to list view
    @domainSearchResultView = new KDView 
    
    @header = new KDHeaderView
      type: "big"
      title: "Search Domain Address"
    
    @searchForm = new KDFormViewWithFields
      callback        : @bound "searchDomain"
      buttons         :
        Register      :
          type        : "submit"
          loader      :
            color     : "#444444"
            diameter  : 12
      
      fields            :
        domainName      :
          label         : "Domain Name:"
          name          : "domainName"
          placeholder   : "Domain (e.g. www.example.com)"
          validate      :
            rules       :
              required  : yes
            messages    :
              required  : "Please enter a domain name."
        regYears        :
          label         : "Years"
          type          : "select"
          selectOptions : ({title:"#{i} Year#{if i > 1 then 's' else ''}", value:i} for i in [1..10])

    @domainNameFieldView = @searchForm.fields.domainName

    @searchForm.on "FormValidationFailed", =>
      @searchForm.buttons.Register.hideLoader()
      
  searchDomain:->
    domainInputVal = @searchForm.inputs.domainName.getValue()
    regYears       = @searchForm.inputs.regYears.getValue()
    domainInfo     = domainInputVal.split "."
    lastItemIndex  = domainInfo.length-1
    domain         = domainInfo.slice(0, lastItemIndex).join ""
    tld            = domainInfo[lastItemIndex]

    KD.remote.api.JDomain.isDomainAvailable domain, tld, (err, domainStatus)=>
      if err then @notifyUser err

      if domainStatus is "unknown"
        @notifyUser "An unknown error occured. Please try again later."
        @searchForm.buttons.Register.hideLoader()

      if domainStatus in ["regthroughus", "regthroughothers"]
        @notifyUser "This domain is already registered. Please try another domain."
        @searchForm.buttons.Register.hideLoader()

      KD.remote.api.JDomain.registerDomain {domainName:domainInputVal, years:regYears}, (err, domain)=>
        if not err 
          new KDNotificationView
            type  : "top"
            title : "Your domain has been successfully registered."
          @searchForm.buttons.Register.hideLoader()
          @modalTabs.showPaneByIndex 2
          domain.setDomainCNameToProxyDomain()

        warn err

    subView.destroy() for subView, i in @domainNameFieldView.getSubViews() when i > 1


  notifyUser:(msg)=>
    @domainNameFieldView.addSubView new KDCustomHTMLView
      partial: """<div style="color: red; margin-top: 10px; margin-bottom: 10px;">#{msg}</div>"""


  pistachio:->
    """
    {{> @header}}
    {{> @searchForm}}
    {{> @domainSearchResultView}}
    
    """
    
  viewAppended: JView::viewAppended
    

class DomainForwardForm extends KDView
  constructor:(options = {}, data)->
    super options, data
    
    @header = new KDHeaderView 
      type  : "small"
      title : "Forward My Domain"
      
    @forwardForm = new KDFormViewWithFields
      callback          : =>
        {modalTabs,parentData} = @getOptions()
        parentData["selectedDomain"] = @forwardForm.inputs.domainAddress.getValue()
        parentData["newDomain"] = no
        modalTabs.showPaneByIndex 2
        
      buttons           :
        Forward         :
          type          : "submit"
          loader        :
            color       : "#444444"
            diameter    : 12
      
      fields            :
          domainAddress :
            label       : "Enter your domain address"
            placeholder : "mydomain.com"
            validate    :
              rules     :
                required: yes
              messages  :
                requires: "write domain name"
            

  pistachio:->
    """
    {{> @header}}
    {{> @forwardForm}}
    """
    
  viewAppended: JView::viewAppended
  
  
class DomainRegistrationCompleteView extends JView

  constructor:(options = {}, data)->
    super options,data
    
    {orderInfo} = @getOptions()
    
    @header  = new KDHeaderView 
      type  : "Small"
      title : "Domain Registration Complete"
    
    @content = new KDView
      partial : """
      <div class = "hate-that-css-stuff">
        Your #{orderInfo.domain} domain address is linked to -> 
        #{orderInfo.linkedVM} with order id of #{orderInfo.orderId}</br>
        I think we add CNAME record to your domain to point koding.[CNAME * 
        #{orderInfo.linkedVM}] </br>
        May be we should also change your nameservers to us but not sure! </br>
        Please give us some time do update DNS. </br>
        To Team: May be we can put some screen shots to explain what we did to user.
      </div>
      """
      
  pistachio:->
    """
    {{> @header}}
    {{> @content}}
    """
    
class DomainForwardingCompleteView extends JView

  constructor:(options = {}, data)->
    super options,data
    
    {orderInfo} = @getOptions()
    
    @header  = new KDHeaderView 
      type  : "Small"
      title : "Domain Forwarding Complete"
    
    @content = new KDView
      partial : """
      <div class = "hate-that-css-stuff">
        Your #{orderInfo.domain} domain address is linked to -> #{orderInfo.linkedVM} </br>
        You should add CNAME record from your domain name provider.</br>
      </div>
      """
      
  pistachio:->
    """
    {{> @header}}
    {{> @content}}
    """


class DomainSettingsModalForm extends KDModalViewWithForms

  constructor : (options = {}, data) ->
    
    options = {  
      title                             : "Domain Settings"
      overlay                           : no
      width                             : 600
      height                            : "auto"
      cssClass                          : "domain-settings-modal-view"
      tabs                              :
        navigable                       : yes
        goToNextFormOnSubmit            : no
        forms                           :
          "Domain Information"          :
            fields                      :
              DomainOption              :
                name                    : "DomainOption"
                label                   : "Created at"
                type                    : "text"
                defaultValue            : "2012/12/12"
                disabled                : yes
                partial                 : =>"asdasd"
                                  
          "Domain Contact Information"  :
            buttons                     : null
            fields                      : {}    
          
          "DNS Management"              :
            buttons                     : null
            fields                      : {}
              
          "Statitics"                   :
            buttons                     : null
            fields                      : {}
    }
    
    super options, data




