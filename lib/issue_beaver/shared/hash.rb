class Hash

  def except(*blacklist)
    {}.tap do |h|
      (keys - blacklist - blacklist.map(&:to_s)).each { |k| h[k] = self[k] }
    end
  end


  def only(*whitelist)
    {}.tap do |h|
      (keys & (whitelist | whitelist.map(&:to_s))).each { |k| h[k] = self[k] }
    end
  end

end