require "test_helper"

class RecurrenceRuleTest < ActiveSupport::TestCase
  # === next_date_after ===

  test "next_date_after daily interval=1" do
    rule = build_rule(frequency: "daily", interval: 1)
    assert_equal Date.new(2026, 4, 7), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after daily interval=3" do
    rule = build_rule(frequency: "daily", interval: 3)
    assert_equal Date.new(2026, 4, 9), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after weekly interval=1 with no BYDAY" do
    rule = build_rule(frequency: "weekly", interval: 1)
    assert_equal Date.new(2026, 4, 13), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after weekly interval=2" do
    rule = build_rule(frequency: "weekly", interval: 2)
    assert_equal Date.new(2026, 4, 20), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after weekly with BYDAY selects next matching weekday" do
    rule = build_rule(frequency: "weekly", interval: 1, by_weekday: "mo,we,fr")
    assert_equal Date.new(2026, 4, 8), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after monthly" do
    rule = build_rule(frequency: "monthly", interval: 1)
    assert_equal Date.new(2026, 5, 6), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after yearly" do
    rule = build_rule(frequency: "yearly", interval: 1)
    assert_equal Date.new(2027, 4, 6), rule.next_date_after(Date.new(2026, 4, 6))
  end

  test "next_date_after returns nil when date is nil" do
    rule = build_rule(frequency: "daily", interval: 1)
    assert_nil rule.next_date_after(nil)
  end

  # === to_ical ===

  test "to_ical daily interval=2" do
    rule = build_rule(frequency: "daily", interval: 2)
    assert_equal "FREQ=DAILY;INTERVAL=2", rule.to_ical
  end

  test "to_ical weekly with BYDAY" do
    rule = build_rule(frequency: "weekly", interval: 1, by_weekday: "mo,we,fr")
    assert_equal "FREQ=WEEKLY;BYDAY=MO,WE,FR", rule.to_ical
  end

  test "to_ical monthly with count" do
    rule = build_rule(frequency: "monthly", interval: 1, end_mode: "count", count: 5)
    assert_equal "FREQ=MONTHLY;COUNT=5", rule.to_ical
  end

  test "to_ical yearly with until" do
    rule = build_rule(frequency: "yearly", interval: 1, end_mode: "until", until_date: Date.new(2028, 1, 1))
    assert_match(/\AFREQ=YEARLY;UNTIL=20280101T/, rule.to_ical)
  end

  # === humanize ===

  test "humanize daily interval=1" do
    rule = build_rule(frequency: "daily", interval: 1)
    assert_equal "毎日", humanize(rule)
  end

  test "humanize daily interval=3" do
    rule = build_rule(frequency: "daily", interval: 3)
    assert_equal "3日ごと", humanize(rule)
  end

  test "humanize weekly with MWF" do
    rule = build_rule(frequency: "weekly", interval: 1, by_weekday: "mo,we,fr")
    assert_equal "毎週月・水・金", humanize(rule)
  end

  test "humanize weekly without BYDAY" do
    rule = build_rule(frequency: "weekly", interval: 1)
    assert_equal "毎週", humanize(rule)
  end

  test "humanize weekly interval=2 with BYDAY" do
    rule = build_rule(frequency: "weekly", interval: 2, by_weekday: "tu")
    assert_equal "2週間ごと（火）", humanize(rule)
  end

  test "humanize monthly interval=1" do
    rule = build_rule(frequency: "monthly", interval: 1)
    assert_equal "毎月", humanize(rule)
  end

  test "humanize monthly interval=3" do
    rule = build_rule(frequency: "monthly", interval: 3)
    assert_equal "3ヶ月ごと", humanize(rule)
  end

  test "humanize yearly interval=1" do
    rule = build_rule(frequency: "yearly", interval: 1)
    assert_equal "毎年", humanize(rule)
  end

  test "humanize appends count end suffix" do
    rule = build_rule(frequency: "daily", interval: 1, end_mode: "count", count: 5)
    assert_includes humanize(rule), "全5回"
  end

  test "humanize appends until end suffix" do
    rule = build_rule(frequency: "daily", interval: 1, end_mode: "until", until_date: Date.new(2027, 1, 1))
    assert_includes humanize(rule), "まで"
  end

  # === weekday_symbols ===

  test "weekday_symbols returns correct symbols" do
    rule = build_rule(frequency: "weekly", interval: 1, by_weekday: "mo,we,fr")
    assert_equal %i[monday wednesday friday], rule.weekday_symbols
  end

  test "weekday_symbols returns empty array when by_weekday is nil" do
    rule = build_rule(frequency: "weekly", interval: 1)
    assert_equal [], rule.weekday_symbols
  end

  # === equality ===

  test "two rules with same attributes are equal" do
    rule1 = build_rule(frequency: "daily", interval: 1)
    rule2 = build_rule(frequency: "daily", interval: 1)
    assert_equal rule1, rule2
    assert_equal rule1.hash, rule2.hash
  end

  test "two rules with different attributes are not equal" do
    rule1 = build_rule(frequency: "daily", interval: 1)
    rule2 = build_rule(frequency: "daily", interval: 2)
    assert_not_equal rule1, rule2
  end

  # === immutability ===

  test "rule is frozen after construction" do
    rule = build_rule(frequency: "daily", interval: 1)
    assert rule.frozen?
  end

  private

    def build_rule(**attrs)
      RecurrenceRule.new(frequency: "daily", interval: 1, by_weekday: nil,
                         end_mode: "infinite", count: nil, until_date: nil, **attrs)
    end

    def humanize(rule)
      I18n.with_locale(:ja) { rule.humanize }
    end
end
