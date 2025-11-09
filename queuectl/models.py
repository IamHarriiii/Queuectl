"""
Data models for queuectl
Defines Job structure and helper functions
"""
from dataclasses import dataclass, asdict
from typing import Optional
from datetime import datetime
import uuid


@dataclass
class Job:
    """Job model representing a background task"""
    
    id: str
    command: str
    state: str = 'pending'
    attempts: int = 0
    max_retries: int = 3
    worker_id: Optional[str] = None
    locked_at: Optional[str] = None
    run_at: Optional[str] = None
    stdout: Optional[str] = None
    stderr: Optional[str] = None
    exit_code: Optional[int] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    
    def __post_init__(self):
        """Set timestamps if not provided"""
        now = datetime.utcnow().isoformat()
        if self.created_at is None:
            self.created_at = now
        if self.updated_at is None:
            self.updated_at = now
    
    def to_dict(self):
        """Convert job to dictionary"""
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: dict) -> 'Job':
        """Create Job from dictionary"""
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})
    
    @staticmethod
    def generate_id() -> str:
        """Generate unique job ID"""
        return str(uuid.uuid4())
    
    def is_retryable(self) -> bool:
        """Check if job can be retried"""
        return self.attempts < self.max_retries
    
    def should_be_in_dlq(self) -> bool:
        """Check if job should be moved to dead letter queue"""
        return self.attempts >= self.max_retries and self.state == 'failed'


# Job state constants
class JobState:
    """Job state constants"""
    PENDING = 'pending'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    FAILED = 'failed'
    DEAD = 'dead'
    
    @classmethod
    def all_states(cls):
        """Get all valid job states"""
        return [cls.PENDING, cls.PROCESSING, cls.COMPLETED, cls.FAILED, cls.DEAD]
    
    @classmethod
    def is_valid(cls, state: str) -> bool:
        """Check if state is valid"""
        return state in cls.all_states()