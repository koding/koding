include Chef::Mixin::RecipeDefinitionDSLCore

def initialize *args
    super
    @logical_volumes = []
    @action = :create
end

actions :create
attr_reader :logical_volumes

attribute :name,
    :kind_of => String,
    :regex => /[\w+.-]+/,
    :required => true,
    :name_attribute => true,
    :callbacks => {
        "cannot be '.' or '..'" => Proc.new do |value|
            !(value == '.' || value == '..')
        end
    }
attribute :physical_volumes, :kind_of => [ Array, String ], :required => true
attribute :physical_extent_size, :kind_of => String, :regex => /\d+[bBsSkKmMgGtTpPeE]?/

def logical_volume name, &block
    Chef::Log.debug "Creating logical volume #{name}"
    volume = lvm_logical_volume name, &block
    volume.action :nothing
    @logical_volumes << volume
    volume
end
