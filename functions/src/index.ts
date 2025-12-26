import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export triggers
export {onPartnerRequestCreated} from "./triggers/onPartnerRequestCreated";
export {onPartnerRequestAccepted} from "./triggers/onPartnerRequestAccepted";
export {onBothPartnersCompleted} from "./triggers/onBothPartnersCompleted";
export {remindPartner} from "./triggers/onRemindPartner";

// Export scheduled functions
export {dailySubtopicScheduler} from "./scheduled/dailySubtopicScheduler";
