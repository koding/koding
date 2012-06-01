class DefaultAllocations
  
  @applyDefaults =(account)->
    defaults = new DefaultAllocations account
    defaults.applyDefaults()
  
  constructor:(@account)->
    @allocations = [
        new Allocation unit: 'database',      quota: 5
        new Allocation unit: 'domain',        quota: 5
        new Allocation unit: 'repository',    quota: 5
        new Allocation unit: 'disk space',    quota: 1024
        new Allocation unit: 'bandwidth',     quota: 1024
        new Allocation unit: 'dollar',        quota: 5.50
      ]
  
  applyDefaults:->
    for allocation in @allocations
      @account.get().allocations.push allocation