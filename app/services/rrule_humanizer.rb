class RruleHumanizer
  WEEKDAY_ORDER = %w[mo tu we th fr sa su].freeze

  def initialize(task_series)
    @series = task_series
  end

  def to_s
    [frequency_label, end_suffix].compact_blank.join(" ")
  end

  private

    attr_reader :series

    def frequency_label
      case series.frequency
      when "daily"   then interval_or_default(:daily)
      when "weekly"  then weekly_label
      when "monthly" then interval_or_default(:monthly)
      when "yearly"  then interval_or_default(:yearly)
      end
    end

    def interval_or_default(freq)
      if series.interval.to_i <= 1
        I18n.t("task_series.humanize.every_#{freq}")
      else
        I18n.t("task_series.humanize.every_n_#{freq}", n: series.interval)
      end
    end

    def weekly_label
      base = interval_or_default(:weekly)
      days = weekday_list
      return base if days.blank?

      key = series.interval.to_i <= 1 ? :weekly_on_days : :weekly_on_days_interval
      I18n.t("task_series.humanize.#{key}", base: base, days: days)
    end

    def weekday_list
      return "" if series.by_weekday.blank?

      codes = series.by_weekday.split(",")
      sorted = WEEKDAY_ORDER.select { |c| codes.include?(c) }
      names = sorted.map { |c| I18n.t("task_series.weekdays.#{c}") }
      names.join(I18n.t("task_series.humanize.weekday_separator"))
    end

    def end_suffix
      case series.end_mode
      when "count"
        I18n.t("task_series.humanize.end_count", n: series.count) if series.count.present?
      when "until"
        I18n.t("task_series.humanize.end_until", date: I18n.l(series.until_date)) if series.until_date.present?
      end
    end
end
