# Debug Mode Detection Patterns

Language-specific patterns for detecting and handling debug/development mode.

## Environment Variables (Universal)

Most languages support environment variables. Use `DEBUG=1` or `ENVIRONMENT=development`:

### Python
```python
import os

IS_DEBUG = os.getenv('DEBUG', '0') == '1'
# or
IS_DEBUG = os.getenv('ENVIRONMENT', '').lower() == 'development'

if IS_DEBUG:
    print("Debug mode enabled")
```

### Node.js / TypeScript
```typescript
const IS_DEBUG = process.env.DEBUG === '1';
// or
const IS_DEBUG = process.env.NODE_ENV === 'development';

if (IS_DEBUG) {
    console.log("Debug mode enabled");
}
```

### Ruby
```ruby
IS_DEBUG = ENV['DEBUG'] == '1'
# or
IS_DEBUG = ENV['RACK_ENV'] == 'development'

puts "Debug mode enabled" if IS_DEBUG
```

### PHP
```php
$isDebug = getenv('DEBUG') === '1';
// or
$isDebug = getenv('ENVIRONMENT') === 'development';

if ($isDebug) {
    echo "Debug mode enabled";
}
```

### Go
```go
import "os"

isDebug := os.Getenv("DEBUG") == "1"
// or
isDebug := os.Getenv("ENVIRONMENT") == "development"

if isDebug {
    fmt.Println("Debug mode enabled")
}
```

### Rust (using dotenv)
```rust
use std::env;

let is_debug = env::var("DEBUG").unwrap_or_default() == "1";
// or
let is_debug = env::var("ENVIRONMENT").unwrap_or_default() == "development";

if is_debug {
    println!("Debug mode enabled");
}
```

---

## Build Tags / Conditional Compilation

### Go (Build Tags)
```go
// +build debug

package main

import "fmt"

func init() {
    fmt.Println("Debug build")
}
```

Build with: `go build -tags debug`

### Rust (Conditional Compilation)
```rust
#[cfg(debug_assertions)]
fn debug_only_function() {
    println!("Debug mode");
}

#[cfg(not(debug_assertions))]
fn debug_only_function() {
    // No-op in release
}
```

### C/C++ (Preprocessor)
```c
#ifdef DEBUG
#define LOG(msg) printf("DEBUG: %s\n", msg)
#else
#define LOG(msg) // No-op in release
#endif
```

Compile with: `gcc -DDEBUG main.c`

---

## Framework-Specific Patterns

### Flask (Python)
```python
from flask import Flask

app = Flask(__name__)

if app.debug:
    print("Flask debug mode enabled")
```

### Django (Python)
```python
from django.conf import settings

if settings.DEBUG:
    print("Django debug mode enabled")
```

### Express.js (Node.js)
```javascript
const app = require('express')();

const isDebug = app.get('env') === 'development';

if (isDebug) {
    console.log("Express debug mode enabled");
}
```

### Rails (Ruby)
```ruby
if Rails.env.development?
    puts "Rails development mode"
end
```

### Laravel (PHP)
```php
if (config('app.debug')) {
    echo "Laravel debug mode enabled";
}
```

---

## dotenv File Loading

Most ecosystems have `.env` file loaders:

### Python (python-dotenv)
```python
from dotenv import load_dotenv
import os

load_dotenv('.env.development')  # or .env.production

DEBUG = os.getenv('DEBUG', '0') == '1'
```

### Node.js (dotenv)
```javascript
require('dotenv').config({ path: '.env.development' });

const isDebug = process.env.DEBUG === '1';
```

### Go (godotenv)
```go
import "github.com/joho/godotenv"

godotenv.Load(".env.development")
isDebug := os.Getenv("DEBUG") == "1"
```

### Ruby (dotenv)
```ruby
require 'dotenv'

Dotenv.load('.env.development')
is_debug = ENV['DEBUG'] == '1'
```

---

## Best Practices

1. **Default to Production**: If env var is missing, default to production/release mode
2. **Explicit is Better**: Use `DEBUG=1` rather than just `DEBUG` for clarity
3. **Multiple Indicators**: Support both `DEBUG` and framework-specific vars (`NODE_ENV`, `RACK_ENV`, etc.)
4. **Environment Files**: Use `.env.development` and `.env.production` for different environments
5. **Never Commit Secrets**: Add `.env.local` to `.gitignore` for local overrides
6. **Document Requirements**: List required environment variables in README

---

## Example: Multi-Language Project Structure

```
.
├── .env.development      # Development environment variables
├── .env.production       # Production environment variables
├── .env.local           # Local overrides (gitignored)
├── .gitignore           # Ignore .env.local
├── backend/
│   ├── python/
│   │   └── config.py    # Load from .env.development
│   └── go/
│       └── config.go    # Load from .env.development
└── frontend/
    └── .env.development # Next.js specific
```

---

## Debugging Checklist

When setting up debug mode for a new language/framework:

- [ ] Choose environment variable pattern (`DEBUG=1` or `ENVIRONMENT=development`)
- [ ] Create `.env.development` and `.env.production` templates
- [ ] Add `.env.local` to `.gitignore`
- [ ] Implement debug mode detection in application entry point
- [ ] Configure logging based on debug mode
- [ ] Test both debug and production modes
- [ ] Document environment variables in README
