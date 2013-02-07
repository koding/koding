actions :create

def initialize *args
    super
    @action = :create
end

must_be_greater_than_0 = {
   'must be greater than 0' => Proc.new { |value| value > 0 }
}

attribute :name, 
    :kind_of => String,
    :regex => /[\w+.-]+/,
    :name_attribute => true,
    :required => true,
    :callbacks => {
        "cannot be '.', '..', 'snapshot', or 'pvmove'" => Proc.new do |value|
            !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
        end,
        "cannot contain the strings '_mlog' or '_mimage'" => Proc.new do |value|
            !value.match /.*(_mlog|_mimage).*/
        end
    }
attribute :group, :kind_of => String
attribute :size, :kind_of => String, :regex => /\d+[kKmMgGtT]|(\d{2}|100)%(FREE|VG|PVS)|\d+/, :required => true
attribute :filesystem, :kind_of => String
attribute :mount_point, :kind_of => Hash, :callbacks => {
    ': location is required!' => Proc.new do |value| 
        value[:location] && !value[:location].empty?
    end,
    ': location must be an absolute path!' => Proc.new do |value| 
        matches = value[:location] =~ %r{^/[^\0]*} 
        !matches.nil?
    end 
}
attribute :physical_volumes, :kind_of => [String, Array]
attribute :stripes, :kind_of => Integer, :callbacks => must_be_greater_than_0
attribute :stripe_size, :kind_of => Integer, :callbacks => {
    'must be a power of 2' => Proc.new do |value| 
        return Math.log2(value) % 1 == 0
    end
}
attribute :mirrors, :kind_of => Integer, :callbacks => must_be_greater_than_0
attribute :contiguous, :kind_of => [TrueClass, FalseClass]
attribute :readahead, :kind_of => [ Integer, String ], :equal_to => [ 2..120, 'auto', 'none' ].flatten!
