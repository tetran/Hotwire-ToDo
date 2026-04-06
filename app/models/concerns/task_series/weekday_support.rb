class TaskSeries
  module WeekdaySupport
    extend ActiveSupport::Concern

    WEEKDAYS = %w[mo tu we th fr sa su].freeze
    WEEKDAY_TO_SYMBOL = {
      "mo" => :monday,
      "tu" => :tuesday,
      "we" => :wednesday,
      "th" => :thursday,
      "fr" => :friday,
      "sa" => :saturday,
      "su" => :sunday,
    }.freeze

    included do
      validate :by_weekday_format
      validate :by_weekday_only_for_weekly
      before_validation :normalize_by_weekday
    end

    def weekday_symbols
      return [] if by_weekday.blank?

      by_weekday.split(",").filter_map { |code| WEEKDAY_TO_SYMBOL[code.strip.downcase] }
    end

    private

      def normalize_by_weekday
        return if by_weekday.blank?

        codes = by_weekday.to_s.downcase.split(",").map(&:strip).compact_blank.uniq
        self.by_weekday = codes.join(",")
      end

      def by_weekday_format
        return if by_weekday.blank?

        invalid = by_weekday.split(",").reject { |c| WEEKDAYS.include?(c) }
        errors.add(:by_weekday, :invalid) if invalid.any?
      end

      def by_weekday_only_for_weekly
        return if by_weekday.blank?
        return if weekly?

        errors.add(:by_weekday, :only_for_weekly)
      end
  end
end
