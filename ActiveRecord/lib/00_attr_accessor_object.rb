class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |method_name|
        self.define_method(method_name) do
          self.instance_variable_get("@#{method_name}")
        end
        set_method_name = method_name.to_s + "="
        self.define_method(set_method_name) do |arg = nil|
          self.instance_variable_set("@#{method_name}", arg)
        end
    end
  end
end
