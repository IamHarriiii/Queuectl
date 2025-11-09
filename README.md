# queuectl - Background Job Queue System

A production-grade CLI-based background job queue system with worker processes, retry logic with exponential backoff, and Dead Letter Queue (DLQ) support.

## 🎯 Features

- ✅ **Job Queue Management** - Enqueue and manage background jobs
- ✅ **Multiple Workers** - Run concurrent worker processes
- ✅ **Automatic Retries** - Failed jobs retry with exponential backoff
- ✅ **Dead Letter Queue** - Permanently failed jobs moved to DLQ
- ✅ **Persistent Storage** - SQLite-based storage survives restarts
- ✅ **Safety Timeout** - Automatic recovery of jobs from crashed workers
- ✅ **Job Output Logging** - Capture stdout, stderr, and exit codes
- ✅ **Configurable** - Runtime configuration via CLI
- ✅ **Clean CLI Interface** - Intuitive command structure

## 📋 Requirements

- Python 3.8+
- click library

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/IamHarriiii/Queuectl.git
cd queuectl
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Install queuectl

```bash
pip install -e .
```

This makes the `queuectl` command available system-wide.

### 4. Verify Installation

```bash
queuectl --help
```

## 💻 Usage Examples

### Enqueue a Job

```bash
# Simple job
queuectl enqueue '{"id":"job1","command":"echo Hello World"}'

# Job with custom retry count
queuectl enqueue '{"id":"job2","command":"sleep 5","max_retries":5}'

# Job without explicit ID (auto-generated)
queuectl enqueue '{"command":"ls -la"}'
```

### Start Workers

```bash
# Start single worker
queuectl worker start

# Start multiple workers
queuectl worker start --count 3
```

Workers will run in foreground. Press `Ctrl+C` to stop them gracefully.

### Check Queue Status

```bash
queuectl status
```

**Output:**
```
==================================================
QUEUE STATUS
==================================================

Jobs:
  Pending:        3
  Processing:     1
  Completed:     10
  Failed:         0
  Dead (DLQ):     2
  --------------------
  Total:         16

Active Workers: 1

Configuration:
  backoff_base: 2
  job_timeout: 300
  max_retries: 3
  worker_poll_interval: 1
==================================================
```

### List Jobs

```bash
# List all jobs
queuectl list

# List jobs by state
queuectl list --state pending
queuectl list --state completed
queuectl list --state failed

# Limit results
queuectl list --limit 50
```

### Dead Letter Queue Management

```bash
# List jobs in DLQ
queuectl dlq list

# Retry a job from DLQ
queuectl dlq retry job1
```

### Configuration Management

```bash
# View all configuration
queuectl config list

# Get specific config value
queuectl config get max-retries

# Set configuration
queuectl config set max-retries 5
queuectl config set backoff-base 3
queuectl config set job-timeout 600
```

## 🏗️ Architecture Overview

### Components

```
┌─────────────┐
│   CLI       │  User interface
└──────┬──────┘
       │
┌──────▼──────┐
│   Queue     │  Job management
└──────┬──────┘
       │
┌──────▼──────┐
│  Storage    │  SQLite persistence
└─────────────┘

┌─────────────┐
│  Workers    │  Job execution (multi-process)
└──────┬──────┘
       │
┌──────▼──────┐
│  Executor   │  Command execution
└─────────────┘
```

### Job Lifecycle

```
[ENQUEUE]
    ↓
PENDING ──→ PROCESSING ──→ COMPLETED ✓
    ↑           ↓
    │      FAILED (attempts < max_retries)
    │           ↓
    └───── (exponential backoff wait)
                ↓
           DEAD (DLQ) ✗
```

### Data Flow

1. **Job Creation**: User enqueues job via CLI
2. **Job Claiming**: Worker atomically claims pending job from queue
3. **Execution**: Worker executes command via subprocess
4. **Outcome Handling**:
   - **Success** (exit code 0) → Mark as `completed`
   - **Failure** (non-zero exit code):
     - If retries remaining → Schedule retry with backoff → Mark as `pending`
     - If no retries left → Move to DLQ → Mark as `dead`

### Worker Coordination

**Race Condition Prevention:**
- Uses atomic SQL UPDATE with WHERE clause
- Only one worker can claim a job
- Includes safety timeout for crashed workers (5 minutes)

**SQL Query:**
```sql
UPDATE jobs 
SET state='processing', worker_id=?, locked_at=CURRENT_TIMESTAMP
WHERE id IN (
    SELECT id FROM jobs
    WHERE (state='pending' OR (state='processing' AND locked_at < datetime('now', '-5 minutes')))
    AND (run_at IS NULL OR run_at <= CURRENT_TIMESTAMP)
    ORDER BY created_at ASC
    LIMIT 1
)
```

### Retry Mechanism

**Exponential Backoff Formula:**
```
delay = base ^ attempts (seconds)
```

**Example** (base=2, max_retries=3):
- Attempt 1 fails → Wait 2¹ = 2 seconds
- Attempt 2 fails → Wait 2² = 4 seconds  
- Attempt 3 fails → Wait 2³ = 8 seconds
- After attempt 3 → Move to DLQ

### Persistence

**Storage:** SQLite database at `~/.queuectl/queuectl.db`

**Schema:**
```sql
jobs (
    id, command, state, attempts, max_retries,
    worker_id, locked_at, run_at,
    stdout, stderr, exit_code,
    created_at, updated_at
)

config (
    key, value
)
```

## 🔧 Configuration Options

| Key | Default | Description |
|-----|---------|-------------|
| `max_retries` | 3 | Maximum retry attempts before DLQ |
| `backoff_base` | 2 | Base for exponential backoff calculation |
| `job_timeout` | 300 | Job execution timeout in seconds |
| `worker_poll_interval` | 1 | Worker polling interval in seconds |

## ⚙️ Assumptions & Trade-offs

### Assumptions

1. **Trusted Environment**: Commands are provided by trusted users via CLI (not external API)
2. **Single Machine**: System runs on a single machine (not distributed)
3. **Moderate Load**: Designed for moderate job volumes (thousands, not millions)

### Trade-offs

#### Using `shell=True` in subprocess

**Decision**: Use `shell=True` for command execution

**Rationale:**
- Allows compound commands like `echo "Hi" && sleep 2`
- Enables shell features (pipes, redirects, environment variables)
- Assignment assumes simple shell commands

**Risk**: Shell injection if untrusted input
- **Mitigation**: Commands only come from trusted CLI interface
- **Documentation**: Clearly documented in code and README

**Production Alternative**: For untrusted input, use `shell=False` with command parsing and validation

#### Worker Process Management

**Decision**: Foreground worker processes (multiprocessing)

**Rationale:**
- Simpler implementation and debugging
- Easier graceful shutdown (signal handling)
- Better for demonstration and testing

**Alternative**: Daemon workers with PID files
- More complex but better for production deployment
- Could be added as enhancement

#### Storage Choice (SQLite vs JSON)

**Decision**: SQLite

**Rationale:**
- ACID compliance for atomicity
- Built-in locking mechanisms
- Better query performance
- Indexed lookups

**Trade-off**: Slightly heavier than JSON files, but worth it for reliability

## 🧪 Testing Instructions

### Automated Test Suite

Run the comprehensive test suite:

```bash
python tests/test_scenarios.py
```

**Tests Included:**
1. Basic job completes successfully
2. Failed job retries with backoff and moves to DLQ
3. Multiple workers process jobs without overlap
4. Invalid commands fail gracefully
5. Job data survives restart
6. DLQ retry functionality

### Manual Testing

**Test 1: Basic Success Flow**
```bash
queuectl enqueue '{"id":"test1","command":"echo Success"}'
queuectl worker start --count 1 &
sleep 3
queuectl list --state completed
```

**Test 2: Retry and DLQ**
```bash
queuectl config set max-retries 2
queuectl enqueue '{"id":"test2","command":"exit 1","max_retries":2}'
queuectl worker start --count 1 &
sleep 5
queuectl dlq list
```

**Test 3: Multiple Workers**
```bash
for i in {1..5}; do
    queuectl enqueue "{\"id\":\"job$i\",\"command\":\"sleep 2\"}"
done
queuectl worker start --count 3 &
sleep 5
queuectl status
```

## 📊 Project Structure

```
queuectl/
├── queuectl/
│   ├── __init__.py       # Package initialization
│   ├── cli.py            # CLI commands (Click)
│   ├── queue.py          # Queue operations
│   ├── worker.py         # Worker logic & job execution
│   ├── storage.py        # SQLite database layer
│   ├── config.py         # Configuration management
│   └── models.py         # Job data model
├── tests/
│   └── test_scenarios.py # Integration tests
├── README.md             # This file
├── requirements.txt      # Python dependencies
└── setup.py              # Package setup
```

## 🌟 Bonus Features Implemented

- ✅ **Job timeout handling** - Configurable timeout with subprocess
- ✅ **Scheduled/delayed jobs** - `run_at` field for delayed execution
- ✅ **Job output logging** - Captures stdout, stderr, exit_code
- ✅ **Safety timeout** - Auto-recovery of jobs from crashed workers
- ✅ **DLQ retry** - Move jobs from DLQ back to queue

## 🎥 Demo 

https://drive.google.com/file/d/1xGuwrG4USCyO1zYnsmwxv8DplZ3bvC3A/view?usp=sharing

## 📝 Notes

- Database location: `~/.queuectl/queuectl.db`
- Workers finish current job before shutdown (graceful)
- Job output is truncated to 2000 characters to prevent database bloat
- Atomic operations prevent race conditions between workers

## 🐛 Known Limitations

1. **Single Machine Only**: Not designed for distributed deployment
2. **No Job Priority**: All jobs processed FIFO
3. **Limited Monitoring**: No built-in dashboard (terminal output only)
4. **No Authentication**: Assumes trusted local environment

## 🚀 Future Enhancements

- Job priority queues
- Web dashboard for monitoring
- Job dependencies and workflows
- Metrics and statistics tracking
- Docker deployment support
- API endpoint for job submission

## 📄 License

This project is created for educational purposes as part of a backend developer internship assignment.

## 👤 Author

HARINARAYANAN U
hari.narayanan1402@gmail.com
https://github.com/IamHarriiii

---
