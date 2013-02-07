def initialize *args
    super
    @action = :create
end

attribute :name, :kind_of => String, :name_attribute => true, :required => true
actions :create
