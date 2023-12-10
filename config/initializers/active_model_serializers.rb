# frozen_string_literal: true

# Every API response is enveloped under a root key ({"event": {...}},
# {"events": [...], "meta": {...}}) so that list endpoints have somewhere to put
# pagination metadata and single-resource responses keep the same shape.
ActiveModelSerializers.config.adapter = :json
