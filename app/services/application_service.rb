# frozen_string_literal: true

# Base class for the thin service objects that hold multi-step domain logic.
# Each service returns a Result rather than raising for expected failures, so
# controllers stay declarative and the rules stay testable in isolation.
class ApplicationService
  Result = Struct.new(:success, :payload, :error, :status, keyword_init: true) do
    def success? = success
    def failure? = !success
  end

  def self.call(...) = new(...).call

  private

  def success(payload, status: :ok)
    Result.new(success: true, payload: payload, status: status)
  end

  def failure(error, status: :unprocessable_entity)
    Result.new(success: false, error: error, status: status)
  end
end
