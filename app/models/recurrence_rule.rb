class RecurrenceRule
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
  WEEKDAY_ORDER = WEEKDAYS

  attr_reader :frequency, :interval, :by_weekday, :end_mode, :count, :until_date

  def initialize(**attrs)
    @frequency = attrs.fetch(:frequency).to_s
    @interval = attrs.fetch(:interval, 1).to_i
    @by_weekday = normalize_by_weekday(attrs[:by_weekday])
    @end_mode = attrs.fetch(:end_mode, "infinite").to_s
    @count = attrs[:count]&.to_i
    @until_date = attrs[:until_date]
    freeze
  end

  def next_date_after(date)
    return nil if date.nil?

    anchor = date.to_time
    schedule = IceCube::Schedule.new(anchor)
    schedule.add_recurrence_rule(build_ice_cube_rule)
    schedule.next_occurrence(anchor)&.to_date
  end

  def to_ical
    ice_cube_rule = build_ice_cube_rule
    ice_cube_rule.to_ical
  end

  def humanize
    [frequency_label, end_suffix].compact_blank.join(" ")
  end

  def weekday_symbols
    return [] if by_weekday.blank?

    by_weekday.split(",").filter_map { |code| WEEKDAY_TO_SYMBOL[code.strip.downcase] }
  end

  def ==(other)
    other.is_a?(RecurrenceRule) && state == other.state
  end
  alias eql? ==

  def hash
    [frequency, interval, by_weekday, end_mode, count, until_date].hash
  end

  protected

    def state
      [frequency, interval, by_weekday, end_mode, count, until_date]
    end

  private

    def normalize_by_weekday(value)
      return nil if value.blank?

      value.to_s.downcase.split(",").map(&:strip).compact_blank.uniq.join(",")
    end

    # IceCube rule building

    def build_ice_cube_rule
      rule = base_ice_cube_rule
      apply_ice_cube_termination(rule)
    end

    def base_ice_cube_rule
      case frequency
      when "daily"   then IceCube::Rule.daily(interval)
      when "weekly"  then weekly_ice_cube_rule
      when "monthly" then IceCube::Rule.monthly(interval)
      when "yearly"  then IceCube::Rule.yearly(interval)
      else raise ArgumentError, "Unknown frequency: #{frequency.inspect}"
      end
    end

    def weekly_ice_cube_rule
      rule = IceCube::Rule.weekly(interval)
      syms = weekday_symbols
      rule = rule.day(*syms) if syms.any?
      rule
    end

    def apply_ice_cube_termination(rule)
      case end_mode
      when "count" then count.present? ? rule.count(count) : rule
      when "until" then until_date.present? ? rule.until(until_date_as_utc) : rule
      else rule
      end
    end

    def until_date_as_utc
      Time.utc(until_date.year, until_date.month, until_date.day)
    end

    # Humanization

    def frequency_label
      case frequency
      when "daily"   then interval_or_default(:daily)
      when "weekly"  then weekly_label
      when "monthly" then interval_or_default(:monthly)
      when "yearly"  then interval_or_default(:yearly)
      end
    end

    def interval_or_default(freq)
      if interval <= 1
        I18n.t("task_series.humanize.every_#{freq}")
      else
        I18n.t("task_series.humanize.every_n_#{freq}", n: interval)
      end
    end

    def weekly_label
      base = interval_or_default(:weekly)
      days = weekday_list
      return base if days.blank?

      key = interval <= 1 ? :weekly_on_days : :weekly_on_days_interval
      I18n.t("task_series.humanize.#{key}", base: base, days: days)
    end

    def weekday_list
      return "" if by_weekday.blank?

      codes = by_weekday.split(",")
      sorted = WEEKDAY_ORDER.select { |c| codes.include?(c) }
      names = sorted.map { |c| I18n.t("task_series.weekdays.#{c}") }
      names.join(I18n.t("task_series.humanize.weekday_separator"))
    end

    def end_suffix
      case end_mode
      when "count"
        I18n.t("task_series.humanize.end_count", n: count) if count.present?
      when "until"
        I18n.t("task_series.humanize.end_until", date: I18n.l(until_date)) if until_date.present?
      end
    end
end
