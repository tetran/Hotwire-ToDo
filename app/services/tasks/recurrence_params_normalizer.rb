module Tasks
  class RecurrenceParamsNormalizer
    delegate :present?, :blank?, to: :@params

    def initialize(params)
      @params = params
    end

    def enabled?
      return false if @params.blank?

      ActiveModel::Type::Boolean.new.cast(@params[:enabled])
    end

    def by_weekday
      normalize_by_weekday(@params[:by_weekday])
    end

    def series_attrs
      {
        frequency: @params[:frequency],
        interval: @params[:interval].presence || 1,
        by_weekday: by_weekday,
        end_mode: @params[:end_mode].presence || "infinite",
        count: @params[:count].presence,
        until_date: @params[:until_date].presence,
      }
    end

    def template_update_attrs
      present_attrs.merge(optional_attrs)
    end

    def subtask_names
      Array(@params[:subtask_names]).compact_blank
    end

    def template_changed?(series)
      changed_present_fields?(series) ||
        changed_by_weekday?(series) ||
        changed_nullable_fields?(series)
    end

    private

      def present_attrs
        attrs = {}
        attrs[:frequency] = @params[:frequency] if present_key?(:frequency)
        attrs[:end_mode] = @params[:end_mode] if present_key?(:end_mode)
        attrs[:interval] = @params[:interval].to_i if present_key?(:interval)
        attrs
      end

      def optional_attrs
        attrs = {}
        attrs[:by_weekday] = by_weekday if @params.key?(:by_weekday)
        attrs[:count] = @params[:count].presence if @params.key?(:count)
        attrs[:until_date] = @params[:until_date].presence if @params.key?(:until_date)
        attrs
      end

      def changed_present_fields?(series)
        string_field_changed?(:frequency, series.frequency) ||
          string_field_changed?(:end_mode, series.end_mode) ||
          int_field_changed?(:interval, series.interval)
      end

      def changed_by_weekday?(series)
        @params.key?(:by_weekday) && by_weekday.to_s != series.by_weekday.to_s
      end

      def changed_nullable_fields?(series)
        nullable_changed?(:count, series.count) || nullable_changed?(:until_date, series.until_date)
      end

      def nullable_changed?(field, current)
        @params.key?(field) && @params[field].to_s != current.to_s
      end

      def string_field_changed?(field, current_value)
        present_key?(field) && @params[field].to_s != current_value.to_s
      end

      def int_field_changed?(field, current_value)
        present_key?(field) && @params[field].to_i != current_value
      end

      def present_key?(key)
        @params.key?(key) && @params[key].present?
      end

      def normalize_by_weekday(value)
        return nil if value.blank?

        Array(value).compact_blank.join(",").presence
      end
  end
end
