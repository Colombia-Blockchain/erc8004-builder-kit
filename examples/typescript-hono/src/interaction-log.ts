/**
 * Circular Buffer Interaction Log
 *
 * Thread-safe, memory-bounded log for tracking agent interactions.
 * Useful for debugging, analytics, and OASF heartbeat data.
 *
 * Usage:
 *   const log = new InteractionLog(1000);
 *   log.add({ type: "mcp", tool: "getPrice", duration: 150 });
 *   const recent = log.getRecent(10);
 */

interface LogEntry {
  timestamp: string;
  type: string;
  [key: string]: unknown;
}

export class InteractionLog {
  private buffer: LogEntry[];
  private head = 0;
  private count = 0;

  constructor(private maxSize: number = 1000) {
    this.buffer = new Array(maxSize);
  }

  add(entry: Omit<LogEntry, "timestamp">): void {
    const full = {
      ...entry,
      timestamp: new Date().toISOString(),
    } as LogEntry;
    this.buffer[this.head] = full;
    this.head = (this.head + 1) % this.maxSize;
    if (this.count < this.maxSize) this.count++;
  }

  getRecent(n: number = 10): LogEntry[] {
    const result: LogEntry[] = [];
    const start = (this.head - Math.min(n, this.count) + this.maxSize) % this.maxSize;
    for (let i = 0; i < Math.min(n, this.count); i++) {
      const idx = (start + i) % this.maxSize;
      if (this.buffer[idx]) result.push(this.buffer[idx]);
    }
    return result;
  }

  getStats(): { total: number; byType: Record<string, number> } {
    const byType: Record<string, number> = {};
    for (let i = 0; i < this.count; i++) {
      const idx = (this.head - this.count + i + this.maxSize) % this.maxSize;
      const entry = this.buffer[idx];
      if (entry) {
        byType[entry.type] = (byType[entry.type] || 0) + 1;
      }
    }
    return { total: this.count, byType };
  }

  clear(): void {
    this.head = 0;
    this.count = 0;
  }
}
