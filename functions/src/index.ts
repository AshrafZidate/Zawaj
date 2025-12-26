import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export triggers
export {onPartnerRequestAccepted} from "./triggers/onPartnerRequestAccepted";
export {onBothPartnersCompleted} from "./triggers/onBothPartnersCompleted";

// Export scheduled functions
export {dailySubtopicScheduler} from "./scheduled/dailySubtopicScheduler";
