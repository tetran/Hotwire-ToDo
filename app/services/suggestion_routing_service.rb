class SuggestionRoutingService
  def self.select_entry
    config = SuggestionConfig.current
    return nil unless config

    entries = config.entries.to_a
    return entries.first if entries.size == 1

    roll = Kernel.rand
    cumulative = 0.0

    entries.each do |entry|
      cumulative += entry.weight / 100.0
      return entry if roll < cumulative
    end

    entries.last
  end
end
