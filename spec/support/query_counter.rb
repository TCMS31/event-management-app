# frozen_string_literal: true

# Counts the SQL statements a block issues. Used to pin the N+1 fixes in place:
# an assertion on behaviour alone would still pass if listing 50 events went
# back to the database 100 times.
module QueryCounter
  IGNORED = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT|SHOW|SET)\b/i

  def count_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      next if payload[:cached]
      next if payload[:name].to_s.in?(%w[SCHEMA TRANSACTION])
      next if payload[:sql].to_s.match?(IGNORED)

      queries << payload[:sql]
    end

    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

RSpec.configure { |config| config.include QueryCounter }
