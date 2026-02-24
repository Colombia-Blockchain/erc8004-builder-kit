"""
Circular Buffer Interaction Log (Thread-Safe)

Memory-bounded log for tracking agent interactions.
Useful for debugging, analytics, and OASF heartbeat data.

Usage:
    from interaction_log import InteractionLog

    log = InteractionLog(max_size=1000)
    log.add(type="mcp", tool="getPrice", duration=150)
    recent = log.get_recent(10)
"""

import threading
from datetime import datetime, timezone
from typing import Any


class InteractionLog:
    def __init__(self, max_size: int = 1000):
        self._buffer: list[dict[str, Any] | None] = [None] * max_size
        self._max_size = max_size
        self._head = 0
        self._count = 0
        self._lock = threading.Lock()

    def add(self, **kwargs: Any) -> None:
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **kwargs,
        }
        with self._lock:
            self._buffer[self._head] = entry
            self._head = (self._head + 1) % self._max_size
            if self._count < self._max_size:
                self._count += 1

    def get_recent(self, n: int = 10) -> list[dict[str, Any]]:
        with self._lock:
            result = []
            count = min(n, self._count)
            start = (self._head - count + self._max_size) % self._max_size
            for i in range(count):
                idx = (start + i) % self._max_size
                entry = self._buffer[idx]
                if entry is not None:
                    result.append(entry)
            return result

    def get_stats(self) -> dict[str, Any]:
        with self._lock:
            by_type: dict[str, int] = {}
            for i in range(self._count):
                idx = (self._head - self._count + i + self._max_size) % self._max_size
                entry = self._buffer[idx]
                if entry and "type" in entry:
                    t = entry["type"]
                    by_type[t] = by_type.get(t, 0) + 1
            return {"total": self._count, "by_type": by_type}

    def clear(self) -> None:
        with self._lock:
            self._head = 0
            self._count = 0
