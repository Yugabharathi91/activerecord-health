# ActiveRecord::Health Specification

## Overview

A gem that checks database health by monitoring active session count relative to available vCPUs. Intended to be used for automatic load shedding.

## Configuration

```ruby
ActiveRecord::Health.configure do |config|
  config.vcpu_count = 16          # Number of vCPUs on the database server
  config.threshold = 0.75         # Percentage of vCPUs that indicates healthy (default: 0.75)

  # Caching (required)
  config.cache = Rails.cache      # ActiveSupport::Cache compatible store
  config.cache_ttl = 1.minute     # How long to cache health check results (default: 1 minute)
end
```

The gem should raise if `vcpu_count` is not configured.

The gem should raise if `cache` is not configured.

The threshold represents the maximum healthy load. With `vcpu_count = 16` and `threshold = 0.75`, up to 12 active sessions is considered healthy.

## Caching Behavior

Health check results are cached to avoid adding load to an already struggling database.

**Cache key:**
- `activerecord_health:load_pct:<db_config_name>`

The `db_config_name` is derived from `model.connection_db_config.name` (e.g., "primary", "animals").

Only `load_pct` is cached. `ok?` reads the cached `load_pct` and compares it against the configured threshold.

### Circuit breaker behavior:

When the health check query fails (connection error, timeout, etc.):
- `ok?` returns `false` and caches `false` for `cache_ttl`
- This prevents repeated failing queries from piling on

When the database is unhealthy:
- The unhealthy state is cached for `cache_ttl`
- Subsequent calls return the cached `false` without querying

This provides natural circuit breaker behavior: once unhealthy, we stop hitting the database for `cache_ttl` before checking again.

### Cache failure behavior:

If the cache store is unavailable (connection error, timeout, etc.):
- `ok?` returns `true` (fail open)
- `load_pct` returns `0.0`
- This prevents a cache outage from triggering load shedding across all requests

## API

### `ActiveRecord::Health.ok?(model: ActiveRecord::Base)`

Returns `true` if the database is healthy, `false` otherwise.

```ruby
ActiveRecord::Health.ok?
# => true

# With multi-database support (pass the abstract class that connects_to the database)
ActiveRecord::Health.ok?(model: AnimalsRecord)
```

**Parameters:**
- `model` (optional): An ActiveRecord model class (typically an abstract class using `connects_to`). Defaults to `ActiveRecord::Base`.

**Returns:** `Boolean`

### `ActiveRecord::Health.load_pct(model: ActiveRecord::Base)`

Returns the current load as a percentage of vCPUs.

```ruby
ActiveRecord::Health.load_pct
# => 0.75

ActiveRecord::Health.load_pct(model: AnimalsRecord)
# => 0.5
```

**Parameters:**
- `model` (optional): An ActiveRecord model class. Defaults to `ActiveRecord::Base`.

**Returns:** `Float` between 0.0 and potentially > 1.0 (if overloaded)

### `ActiveRecord::Health.sheddable(model: ActiveRecord::Base) { }`

Executes the block only if the database is healthy. Raises `ActiveRecord::Health::Unhealthy` if not.

```ruby
ActiveRecord::Health.sheddable do
  GenerateReport.perform(user_id: current_user.id)
end
# => raises ActiveRecord::Health::Unhealthy if database is overloaded
```

**Parameters:**
- `model` (optional): An ActiveRecord model class. Defaults to `ActiveRecord::Base`.

**Raises:** `ActiveRecord::Health::Unhealthy` if the database is not healthy.

### `ActiveRecord::Health.sheddable_pct(pct:, model: ActiveRecord::Base) { }`

Executes the block only if the database load is below the specified percentage. Useful for progressive load shedding where different operations have different priorities.

```ruby
# Only run if load is below 50% (high priority work gets more headroom)
ActiveRecord::Health.sheddable_pct(pct: 0.5) do
  BulkImport.perform(data)
end

# Only run if load is below 90% (low priority, shed first)
ActiveRecord::Health.sheddable_pct(pct: 0.9) do
  SendAnalyticsEmail.perform(user_id: current_user.id)
end
```

**Parameters:**
- `pct` (required): Maximum load percentage (0.0 to 1.0) at which to execute the block.
- `model` (optional): An ActiveRecord model class. Defaults to `ActiveRecord::Base`.

**Raises:** `ActiveRecord::Health::Unhealthy` if the database load exceeds `pct`.

## Optional Extensions

Require `activerecord-health/extensions` for convenience methods on connection and model objects. Not loaded by default.

```ruby
require "activerecord-health/extensions"
```

### Connection Extension

```ruby
ActiveRecord::Base.connection.healthy?
# => true

ActiveRecord::Base.connection.load_pct
# => 0.75

ReplicaRecord.connection.healthy?
# => true
```

### Model Extension

```ruby
ActiveRecord::Base.database_healthy?
# => true

ReplicaRecord.database_healthy?
# => true
```

## Database Support

### PostgreSQL

Query to get active session count:

```sql
SELECT count(*)
FROM pg_stat_activity
WHERE state = 'active'
  AND backend_type = 'client backend'
  AND pid != pg_backend_pid();
```

### MySQL

We need to detect what mysql version the user is using SELECT VERSION().

Query to get active session count:

### Query (MySQL 8.0.22+)

```sql
SELECT COUNT(*)
FROM performance_schema.processlist
WHERE COMMAND != 'Sleep'
  AND ID != CONNECTION_ID()
  AND USER NOT IN ('event_scheduler', 'system user');
```

### Fallback Query (MySQL 5.1+, MariaDB)

```sql
SELECT COUNT(*)
FROM information_schema.processlist
WHERE Command != 'Sleep'
  AND ID != CONNECTION_ID()
  AND User NOT IN ('event_scheduler', 'system user')
  AND Command NOT IN ('Binlog Dump', 'Binlog Dump GTID');
```

### SQLite 3

Not supported.

## Multi-Database Support

The gem works with Rails' multi-database configuration. Pass the abstract model class that uses `connects_to` for your database:

```ruby
# Check the primary database (default)
ActiveRecord::Health.ok?

# Check a specific database by its abstract model class
ActiveRecord::Health.ok?(model: AnimalsRecord)
```

This follows Rails' pattern where abstract classes define database connections:

```ruby
# app/models/animals_record.rb
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

## Per-Database Configuration

For multi-database setups with different vCPU counts, configure by model class:

```ruby
ActiveRecord::Health.configure do |config|
  config.vcpu_count = 16  # Default for ActiveRecord::Base

  config.for_model(AnimalsRecord) do |db|
    db.vcpu_count = 8
    db.threshold = 0.5
  end
end
```

The gem uses `model.connection_db_config.name` to identify which configuration to use.

## Query Timeout

The health check query has a hardcoded 1 second timeout. If the query times out or fails for any reason, we treat the database as overloaded:
- `ok?` returns `false`
- `load_pct` returns `1.0` (100% load)

This result is cached for `cache_ttl`, providing circuit breaker behavior.

## Error Handling

- If the connection cannot be established, `ok?` returns `false`, `load_pct` returns `1.0`
- If the query fails or times out, `ok?` returns `false`, `load_pct` returns `1.0`

## Usage Examples

### Controller Before Filter

Reject requests with 503 when the database is overloaded:

```ruby
class ReportsController < ApplicationController
  before_action :check_database_health

  private

  def check_database_health
    return if ActiveRecord::Health.ok?
    render json: { error: "Service temporarily unavailable" }, status: :service_unavailable
  end
end
```

### Sidekiq Middleware

Retry jobs in specific queues when the database is unhealthy:

```ruby
# config/initializers/sidekiq.rb
class DatabaseHealthMiddleware
  THROTTLED_QUEUES = %w[reports analytics bulk_import].freeze

  def call(_worker, job, _queue)
    if THROTTLED_QUEUES.include?(job["queue"]) && !ActiveRecord::Health.ok?
      raise ActiveRecord::Health::Unhealthy, "Database is overloaded (#{ActiveRecord::Health.load_pct * 100}%)"
    end
    yield
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add DatabaseHealthMiddleware
  end
end
```

## Testing

We will use Github Actions for CI and Minitest for local testing. Both environments start a mysql and postgres container via docker (latest versions for both).

### Test Structure

```
test/
├── unit/
│   ├── configuration_test.rb
│   ├── health_test.rb
│   └── adapters/
│       ├── postgresql_adapter_test.rb
│       └── mysql_adapter_test.rb
├── integration/
│   ├── postgresql_integration_test.rb
│   └── mysql_integration_test.rb
└── test_helper.rb
```

### Unit Tests

Unit tests mock the database connection and cache store. They test:
- Configuration validation (raises without vcpu_count, raises without cache)
- `ok?` returns correct boolean based on mocked load_pct and threshold
- `load_pct` returns cached value when present
- `sheddable` and `sheddable_pct` raise/execute correctly
- Cache failure behavior (fail open)
- Query timeout behavior (returns 1.0)
- Adapter query generation for each database type

### Integration Tests

Integration tests run against real PostgreSQL and MySQL containers using Docker Compose. They verify the actual session counting queries work correctly under load.

#### Integration Test Approach

Each integration test:

1. **Connects to the containerized database**
2. **Spawns N concurrent connections that execute long-running queries** (e.g., `SELECT pg_sleep(10)` or `SELECT SLEEP(10)`)
3. **Verifies `load_pct` returns the expected value** (N / vcpu_count)
4. **Verifies `ok?` returns the expected boolean** based on threshold
