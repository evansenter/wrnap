module Wrnap
  module Package
    Autoloaded.module {}

    def self.lookup(package_name)
      const_missing("#{package_name}".camelize) || raise(ArgumentError.new("#{package_name} can't be resolved as an executable"))
    end

    def self.const_missing(name)
      if const_defined?(name)
        const_get(name)
      elsif Base.exec_exists?(name)
        module_eval do
          const_set(name, Class.new(Base))
        end
      end
    end
  end
end
