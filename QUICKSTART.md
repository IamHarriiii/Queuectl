# Quick Start Guide

Get up and running with queuectl in under 5 minutes!

## Installation

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Install queuectl
pip install -e .

# 3. Verify installation
queuectl --help
```

## Basic Usage

### 1. Enqueue Your First Job

```bash
queuectl enqueue '{"id":"my-first-job","command":"echo Hello World"}'
```

### 2. Start a Worker

```bash
queuectl worker start
```

Press `Ctrl+C` to stop the worker.

### 3. Check Status

```bash
queuectl status
```

## Common Commands Cheat Sheet

```bash
# Enqueue a job
queuectl enqueue '{"command":"your-command-here"}'

# Start workers
queuectl worker start --count 3

# View queue status
queuectl status

# List all jobs
queuectl list

# List jobs by state
queuectl list --state pending
queuectl list --state completed
queuectl list --state dead

# View Dead Letter Queue
queuectl dlq list

# Retry a failed job
queuectl dlq retry <job-id>

# Configure settings
queuectl config set max-retries 5
queuectl config list
```

## Run the Demo

```bash
chmod +x demo.sh
./demo.sh
```

## Run Tests

```bash
python tests/test_scenarios.py
```

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check out the architecture section to understand how it works
- Experiment with different commands and configurations

## Troubleshooting

**Workers not processing jobs?**
- Check if workers are running: `queuectl status`
- Verify jobs are in `pending` state: `queuectl list --state pending`

**Jobs stuck in processing?**
- The system has a 5-minute safety timeout
- Restart workers to allow stale jobs to be reclaimed

**Database errors?**
- Database location: `~/.queuectl/queuectl.db`
- To reset: `rm -rf ~/.queuectl/`

## Need Help?

```bash
queuectl --help
queuectl worker --help
queuectl config --help
queuectl dlq --help
```