class Hash
  def flatten_hash(hash = nil)
    hash ||= self
    hash.each_with_object({}) do |(k, v), h|
      if v.is_a? Hash
        flatten_hash(v).map do |h_k, h_v|
          h["#{k}.#{h_k}".to_sym] = h_v
        end
      else
        h[k] = v
      end
    end
  end

  # Convert something like:
  #
  #  {'pressrelease.label.one' => "Pressmeddelande"}
  #
  # to:
  #
  # {
  #  :pressrelease => {
  #    :label => {
  #      :one => "Pressmeddelande"
  #    }
  #   }
  # }
  def to_deep_hash
    self.inject({}) do |deep_hash, (key, value)|
      keys = key.to_s.split('.').reverse
      leaf_key = keys.shift
      key_hash = keys.inject({leaf_key.to_sym => value}) { |hash, key| {key.to_sym => hash} }
      deep_hash.deep_merge!(key_hash)
      deep_hash
    end
  end
  # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  def deep_merge!(hash2)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge!(hash2, &merger)
  end
end