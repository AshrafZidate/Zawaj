/**
 * Date utility functions for 12pm GMT scheduling
 */

/**
 * Formats a date as YYYY-MM-DD string in GMT
 */
export function formatDateGMT(date: Date): string {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/**
 * Gets today's date string in YYYY-MM-DD format (GMT)
 */
export function getTodayGMT(): string {
  return formatDateGMT(new Date());
}

/**
 * Calculates the next 12pm GMT date for scheduling
 * If current time is before 12pm GMT today, returns today
 * Otherwise returns tomorrow
 */
export function calculateNext12pmGMTDate(): string {
  const now = new Date();
  const currentHourGMT = now.getUTCHours();

  // If before 12pm GMT, next assignment is today
  // Otherwise, next assignment is tomorrow
  if (currentHourGMT < 12) {
    return formatDateGMT(now);
  } else {
    const tomorrow = new Date(now);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    return formatDateGMT(tomorrow);
  }
}

/**
 * Checks if it's currently 12pm GMT (within the scheduler window)
 */
export function isNoon12pmGMT(): boolean {
  const now = new Date();
  return now.getUTCHours() === 12;
}
