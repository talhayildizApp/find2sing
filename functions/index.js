const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Admin email whitelist - guvenlik icin server-side
const ADMIN_EMAILS = ["talhayildiz94@gmail.com"];

/**
 * Set admin custom claim for a user
 * Callable function - requires authentication
 */
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Verify the caller is already an admin or is in the whitelist
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Giris yapmaniz gerekiyor."
    );
  }

  const callerEmail = context.auth.token.email?.toLowerCase();
  const isCallerAdmin = context.auth.token.admin === true;
  const isCallerWhitelisted = ADMIN_EMAILS.includes(callerEmail);

  if (!isCallerAdmin && !isCallerWhitelisted) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu islemi yapmaya yetkiniz yok."
    );
  }

  const { email } = data;
  if (!email || typeof email !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Gecerli bir email adresi gerekli."
    );
  }

  try {
    const user = await admin.auth().getUserByEmail(email.toLowerCase());
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });

    // Log the action
    await admin.firestore().collection("adminLogs").add({
      action: "setAdminClaim",
      targetEmail: email.toLowerCase(),
      performedBy: callerEmail,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: `${email} admin olarak ayarlandi.` };
  } catch (error) {
    console.error("setAdminClaim error:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Hata: ${error.message}`
    );
  }
});

/**
 * Remove admin custom claim from a user
 */
exports.removeAdminClaim = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Giris yapmaniz gerekiyor."
    );
  }

  const callerEmail = context.auth.token.email?.toLowerCase();
  const isCallerAdmin = context.auth.token.admin === true;
  const isCallerWhitelisted = ADMIN_EMAILS.includes(callerEmail);

  if (!isCallerAdmin && !isCallerWhitelisted) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu islemi yapmaya yetkiniz yok."
    );
  }

  const { email } = data;
  if (!email || typeof email !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Gecerli bir email adresi gerekli."
    );
  }

  // Prevent removing own admin status
  if (email.toLowerCase() === callerEmail) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Kendi admin yetkinizi kaldiramazsiniz."
    );
  }

  try {
    const user = await admin.auth().getUserByEmail(email.toLowerCase());
    await admin.auth().setCustomUserClaims(user.uid, { admin: false });

    await admin.firestore().collection("adminLogs").add({
      action: "removeAdminClaim",
      targetEmail: email.toLowerCase(),
      performedBy: callerEmail,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: `${email} admin yetkisi kaldirildi.` };
  } catch (error) {
    console.error("removeAdminClaim error:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Hata: ${error.message}`
    );
  }
});

/**
 * Check if current user is admin
 * Returns admin status based on custom claims
 */
exports.checkAdminStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return { isAdmin: false, reason: "not_authenticated" };
  }

  const email = context.auth.token.email?.toLowerCase();
  const hasAdminClaim = context.auth.token.admin === true;
  const isWhitelisted = ADMIN_EMAILS.includes(email);

  // If whitelisted but no claim yet, auto-grant
  if (isWhitelisted && !hasAdminClaim) {
    try {
      await admin.auth().setCustomUserClaims(context.auth.uid, { admin: true });
      return { isAdmin: true, reason: "whitelisted_auto_granted" };
    } catch (error) {
      console.error("Auto-grant admin error:", error);
    }
  }

  return {
    isAdmin: hasAdminClaim || isWhitelisted,
    reason: hasAdminClaim ? "custom_claim" : (isWhitelisted ? "whitelisted" : "not_admin"),
  };
});

/**
 * Get admin dashboard stats
 * Aggregates user and game metrics
 */
exports.getAdminStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Giris yapmaniz gerekiyor."
    );
  }

  const isAdmin = context.auth.token.admin === true ||
                  ADMIN_EMAILS.includes(context.auth.token.email?.toLowerCase());

  if (!isAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin yetkisi gerekli."
    );
  }

  const db = admin.firestore();
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  try {
    // User metrics
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map(doc => doc.data());

    const totalUsers = users.length;
    const premiumUsers = users.filter(u => u.isPremium === true).length;

    const dauUsers = users.filter(u => {
      const lastLogin = u.lastLoginAt?.toDate?.() || new Date(0);
      return lastLogin >= oneDayAgo;
    }).length;

    const wauUsers = users.filter(u => {
      const lastLogin = u.lastLoginAt?.toDate?.() || new Date(0);
      return lastLogin >= oneWeekAgo;
    }).length;

    const todayRegistrations = users.filter(u => {
      const createdAt = u.createdAt?.toDate?.() || new Date(0);
      return createdAt >= todayStart;
    }).length;

    // Game metrics from user stats
    const totalGamesPlayed = users.reduce((sum, u) => sum + (u.gamesPlayed || 0), 0);
    const totalSongsFound = users.reduce((sum, u) => sum + (u.totalSongsFound || 0), 0);
    const totalTimePlayed = users.reduce((sum, u) => sum + (u.totalTimePlayed || 0), 0);

    // Content counts
    const categoriesCount = (await db.collection("categories").count().get()).data().count;
    const challengesCount = (await db.collection("challenges").count().get()).data().count;
    const songsCount = (await db.collection("songs").count().get()).data().count;

    return {
      userMetrics: {
        totalUsers,
        premiumUsers,
        dauUsers,
        wauUsers,
        todayRegistrations,
      },
      gameMetrics: {
        totalGamesPlayed,
        totalSongsFound,
        totalTimePlayed,
        avgGameTime: totalGamesPlayed > 0 ? Math.round(totalTimePlayed / totalGamesPlayed) : 0,
      },
      contentMetrics: {
        categories: categoriesCount,
        challenges: challengesCount,
        songs: songsCount,
      },
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error("getAdminStats error:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Istatistik alinamadi: ${error.message}`
    );
  }
});
