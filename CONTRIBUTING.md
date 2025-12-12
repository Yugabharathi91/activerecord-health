## Development

### Requirements

- Ruby 3.2+
- Docker (for integration tests)

### Running Tests

```bash
# Unit tests only
bundle exec rake test

# Start test databases
docker-compose up -d

# All tests (unit + integration)
bundle exec rake test_all

# Stop test databases
docker-compose down
```

### Project Structure

```
lib/
├── activerecord-health.rb          # Main entry point
└── activerecord/
    └── health/
        ├── configuration.rb        # Config handling
        ├── extensions.rb           # Optional model/connection methods
        └── adapters/
            ├── postgresql_adapter.rb
            └── mysql_adapter.rb
test/
├── unit/                           # Fast tests with mocks
└── integration/                    # Tests against real databases
```
