require "test_helper"

class RruleHumanizerTest < ActiveSupport::TestCase
  setup do
    @project = projects(:two)
    @user = users(:regular_user)
  end

  test "daily interval=1" do
    assert_equal "毎日", humanize(frequency: :daily, interval: 1)
  end

  test "daily interval=3" do
    assert_equal "3日ごと", humanize(frequency: :daily, interval: 3)
  end

  test "weekly with MWF" do
    assert_equal "毎週月・水・金", humanize(frequency: :weekly, interval: 1, by_weekday: "mo,we,fr")
  end

  test "weekly without BYDAY" do
    assert_equal "毎週", humanize(frequency: :weekly, interval: 1)
  end

  test "weekly interval=2 with BYDAY" do
    assert_equal "2週間ごと（火）", humanize(frequency: :weekly, interval: 2, by_weekday: "tu")
  end

  test "weekly interval=2 without BYDAY" do
    assert_equal "2週間ごと", humanize(frequency: :weekly, interval: 2)
  end

  test "monthly interval=1" do
    assert_equal "毎月", humanize(frequency: :monthly, interval: 1)
  end

  test "monthly interval=3" do
    assert_equal "3ヶ月ごと", humanize(frequency: :monthly, interval: 3)
  end

  test "yearly interval=1" do
    assert_equal "毎年", humanize(frequency: :yearly, interval: 1)
  end

  test "appends count end suffix" do
    result = humanize(frequency: :daily, interval: 1, end_mode: :count, count: 5)
    assert_includes result, "全5回"
  end

  test "appends until end suffix" do
    result = humanize(frequency: :daily, interval: 1, end_mode: :until, until_date: Date.new(2027, 1, 1))
    assert_includes result, "まで"
  end

  private

    def humanize(**attrs)
      defaults = { project: @project, created_by: @user, name: "x", frequency: :daily, interval: 1,
                   end_mode: :infinite, occurrences_generated: 0 }
      series = TaskSeries.new(defaults.merge(attrs))
      series.valid? # runs normalize & derive
      I18n.with_locale(:ja) { RruleHumanizer.new(series).to_s }
    end
end
