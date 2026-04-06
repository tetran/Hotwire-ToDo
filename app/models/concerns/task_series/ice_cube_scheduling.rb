class TaskSeries
  module IceCubeScheduling
    extend ActiveSupport::Concern

    def next_due_date_after(date)
      return nil if date.nil?

      anchor = date.to_time
      schedule = IceCube::Schedule.new(anchor)
      schedule.add_recurrence_rule(build_ice_cube_rule)
      schedule.next_occurrence(anchor)&.to_date
    end

    private

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
        return rule.count(count) if end_count? && count.present?
        if end_until? && until_date.present?
          return rule.until(Time.utc(until_date.year, until_date.month, until_date.day))
        end

        rule
      end
  end
end
