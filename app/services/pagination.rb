# frozen_string_literal: true

# Keyless offset pagination for the JSON API.
#
# The original `Event.all` was unbounded: a catalogue of 50,000 events would be
# loaded, serialised and pushed through the browser in one response. Every list
# endpoint goes through here instead, and the page size is capped server-side so
# a client cannot ask for everything by passing `per_page=1000000`.
module Pagination
  DEFAULT_PER_PAGE = 10
  MIN_PER_PAGE = 1

  module_function

  def max_per_page
    ENV.fetch('EVENTS_MAX_PAGE_SIZE', 100).to_i
  end

  def page(params:)
    [params[:page].to_i, 1].max
  end

  def per_page(params:)
    requested = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
    requested.clamp(MIN_PER_PAGE, max_per_page)
  end

  # Applies limit/offset to `scope`.
  def apply(scope, params:)
    size = per_page(params: params)
    scope.limit(size).offset((page(params: params) - 1) * size)
  end

  # `count_scope` must be an ungrouped relation — a grouped relation returns a
  # Hash from #count, not an Integer.
  def meta(count_scope, params:)
    size = per_page(params: params)
    total = count_scope.count
    current = page(params: params)

    {
      page: current,
      per_page: size,
      total_count: total,
      total_pages: total.zero? ? 1 : (total.to_f / size).ceil
    }
  end
end
