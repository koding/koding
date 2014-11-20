actions :sync, :clone

attribute :path, :kind_of => String, :name_attribute => true
attribute :repository, :kind_of => String
attribute :reference, :kind_of => [Integer, String]
attribute :key, :kind_of => String
attribute :owner, :kind_of => String
attribute :group, :kind_of => String
attribute :mode, :kind_of => String, :default => '0775'
