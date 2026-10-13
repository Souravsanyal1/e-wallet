import { initializeApp } from "firebase-admin/app";

initializeApp();

// Auth functions
export { authNonce, authVerify } from "./auth";

// Upload signing
export { uploadSign } from "./uploads";

// Conversations
export { createConversation } from "./conversations";

// Payments & Subscriptions
export { createPremiumQuote, verifyPayment, expireSubscriptions, recheckPayments } from "./payments";

// Notifications
export { onMessageCreated } from "./notifications";

// Admin Panel Callables
export {
  adminGetDashboardStats,
  adminSearchUsers,
  adminRevealWallet,
  adminSuspendUser,
  adminBanUser,
  adminListCases,
  adminResolveCase,
  adminListAudit,
} from "./admin";

// Account Management
export { deleteAccount } from "./account";
