#!/bin/bash

# queuectl Demo Script
# This script demonstrates all features of queuectl

set -e

echo "==============================================="
echo "          QUEUECTL DEMONSTRATION"
echo "==============================================="
echo

# Clean slate
echo "🧹 Cleaning previous data..."
rm -rf ~/.queuectl/
echo "✓ Clean slate ready"
echo

# 1. Configuration
echo "==============================================="
echo "1. CONFIGURATION MANAGEMENT"
echo "==============================================="
echo "Viewing default configuration..."
queuectl config list
echo

echo "Setting custom configuration..."
queuectl config set max-retries 3
queuectl config set backoff-base 2
echo "✓ Configuration updated"
echo

# 2. Enqueue Jobs
echo "==============================================="
echo "2. ENQUEUING JOBS"
echo "==============================================="

echo "Enqueuing successful job..."
queuectl enqueue '{"id":"demo-success","command":"echo Hello from queuectl && sleep 1"}'
echo

echo "Enqueuing job that will fail and retry..."
queuectl enqueue '{"id":"demo-fail","command":"exit 1","max_retries":2}'
echo

echo "Enqueuing multiple jobs..."
for i in {1..3}; do
    queuectl enqueue "{\"id\":\"demo-job$i\",\"command\":\"echo Processing job $i && sleep 1\"}"
done
echo

# 3. Check Status
echo "==============================================="
echo "3. QUEUE STATUS (Before Processing)"
echo "==============================================="
queuectl status
echo

# 4. List Pending Jobs
echo "==============================================="
echo "4. LISTING PENDING JOBS"
echo "==============================================="
queuectl list --state pending
echo

# 5. Start Workers
echo "==============================================="
echo "5. STARTING WORKERS"
echo "==============================================="
echo "Starting 2 worker processes..."
echo "(Workers will process jobs in background)"
echo

# Start workers in background
queuectl worker start --count 2 &
WORKER_PID=$!

# Wait for jobs to process
echo "⏳ Waiting for jobs to process (10 seconds)..."
sleep 10

# Kill workers
echo "Stopping workers..."
kill $WORKER_PID 2>/dev/null || true
wait $WORKER_PID 2>/dev/null || true
echo "✓ Workers stopped"
echo

# 6. Check Status After Processing
echo "==============================================="
echo "6. QUEUE STATUS (After Processing)"
echo "==============================================="
queuectl status
echo

# 7. List Completed Jobs
echo "==============================================="
echo "7. LISTING COMPLETED JOBS"
echo "==============================================="
queuectl list --state completed
echo

# 8. Dead Letter Queue
echo "==============================================="
echo "8. DEAD LETTER QUEUE (DLQ)"
echo "==============================================="
queuectl dlq list
echo

# 9. Retry from DLQ
if queuectl dlq list | grep -q "demo-fail"; then
    echo "==============================================="
    echo "9. RETRYING JOB FROM DLQ"
    echo "==============================================="
    echo "Retrying failed job from DLQ..."
    queuectl dlq retry demo-fail
    echo
    
    echo "Checking pending queue..."
    queuectl list --state pending
    echo
fi

# 10. Final Status
echo "==============================================="
echo "10. FINAL STATUS"
echo "==============================================="
queuectl status
echo

echo "==============================================="
echo "          DEMONSTRATION COMPLETE"
echo "==============================================="
echo "✅ All features demonstrated successfully!"
echo
echo "To explore more:"
echo "  - queuectl --help"
echo "  - queuectl worker --help"
echo "  - queuectl config --help"
echo "  - queuectl dlq --help"
echo "Thank you for using queuectl!"