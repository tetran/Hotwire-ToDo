class SuggestionConfig < ApplicationRecord
  MAX_ENTRIES = 3

  has_many :entries, class_name: "SuggestionConfigEntry", dependent: :destroy

  accepts_nested_attributes_for :entries, allow_destroy: true

  validate :at_least_one_entry
  validate :weights_sum_to_one_hundred
  validate :max_entries_count
  validate :no_duplicate_combinations
  validate :only_active_models
  validate :only_active_prompt_sets

  scope :active, -> { where(active: true) }

  def self.current
    active.includes(entries: %i[llm_model prompt_set]).first
  end

  def self.create_with_entries!(entries_attributes:)
    transaction do
      active.update_all(active: false)
      config = new(active: true)
      entries_attributes.each do |attrs|
        config.entries.build(attrs)
      end
      config.save!
      config
    end
  end

  private

    def at_least_one_entry
      return unless entries.reject(&:marked_for_destruction?).empty?

      errors.add(:entries, "must have at least one entry")
    end

    def weights_sum_to_one_hundred
      live_entries = entries.reject(&:marked_for_destruction?)
      return if live_entries.empty?
      return if live_entries.any? { |e| e.weight.nil? }

      total = live_entries.sum(&:weight)
      errors.add(:base, "Weights must sum to 100") unless total == 100
    end

    def max_entries_count
      live_entries_count = entries.count { |entry| !entry.marked_for_destruction? }
      return unless live_entries_count > MAX_ENTRIES

      errors.add(:entries, "cannot have more than #{MAX_ENTRIES} entries")
    end

    def no_duplicate_combinations
      combos = entries.reject(&:marked_for_destruction?).map { |e| [e.llm_model_id, e.prompt_set_id] }
      return unless combos.size != combos.uniq.size

      errors.add(:entries, "cannot have duplicate model and prompt set combinations")
    end

    def only_active_models
      inactive = entries.reject(&:marked_for_destruction?).select { |e| e.llm_model && !e.llm_model.active? }
      return unless inactive.any?

      errors.add(:entries, "must only reference active models")
    end

    def only_active_prompt_sets
      inactive = entries.reject(&:marked_for_destruction?).select { |e| e.prompt_set && !e.prompt_set.active? }
      return unless inactive.any?

      errors.add(:entries, "must only reference active prompt sets")
    end
end
