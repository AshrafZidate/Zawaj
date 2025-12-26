"use strict";
/**
 * Date utility functions for 12pm GMT scheduling
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatDateGMT = formatDateGMT;
exports.getTodayGMT = getTodayGMT;
exports.calculateNext12pmGMTDate = calculateNext12pmGMTDate;
exports.isNoon12pmGMT = isNoon12pmGMT;
/**
 * Formats a date as YYYY-MM-DD string in GMT
 */
function formatDateGMT(date) {
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, "0");
    const day = String(date.getUTCDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}
/**
 * Gets today's date string in YYYY-MM-DD format (GMT)
 */
function getTodayGMT() {
    return formatDateGMT(new Date());
}
/**
 * Calculates the next 12pm GMT date for scheduling
 * If current time is before 12pm GMT today, returns today
 * Otherwise returns tomorrow
 */
function calculateNext12pmGMTDate() {
    const now = new Date();
    const currentHourGMT = now.getUTCHours();
    // If before 12pm GMT, next assignment is today
    // Otherwise, next assignment is tomorrow
    if (currentHourGMT < 12) {
        return formatDateGMT(now);
    }
    else {
        const tomorrow = new Date(now);
        tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
        return formatDateGMT(tomorrow);
    }
}
/**
 * Checks if it's currently 12pm GMT (within the scheduler window)
 */
function isNoon12pmGMT() {
    const now = new Date();
    return now.getUTCHours() === 12;
}
//# sourceMappingURL=dateUtils.js.map