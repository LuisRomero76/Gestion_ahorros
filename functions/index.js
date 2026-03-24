// /**
//  * Import function triggers from their respective submodules:
//  *
//  * const {onCall} = require("firebase-functions/v2/https");
//  * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */

// const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
// const logger = require("firebase-functions/logger");

// // For cost control, you can set the maximum number of containers that can be
// // running at the same time. This helps mitigate the impact of unexpected
// // traffic spikes by instead downgrading performance. This limit is a
// // per-function limit. You can override the limit for each function using the
// // `maxInstances` option in the function's options, e.g.
// // `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// // NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// // functions should each use functions.runWith({ maxInstances: 10 }) instead.
// // In the v1 API, each function can only serve one request per container, so
// // this will be the maximum concurrent request count.
// setGlobalOptions({ maxInstances: 10 });

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });


/**
 * Cloud Functions para Gestion de Ahorros
 *
 * Esta función se dispara automáticamente cuando se crea un nuevo
 * documento en la colección 'records' de Firestore.
 *
 * Envía notificaciones push a todos los usuarios EXCEPTO
 * al que creó el registro.
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Inicializar Firebase Admin SDK
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Trigger: Se ejecuta cuando se crea un nuevo documento en 'records'
 */
exports.onNewRecord = onDocumentCreated("records/{recordId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No hay datos en el snapshot");
    return null;
  }

  const recordData = snapshot.data();
  console.log("Nuevo registro creado:", event.params.recordId);
  console.log("Datos del registro:", JSON.stringify(recordData));

  // Extraer información del registro
  const {
    addedBy,        // UID del usuario que creó el registro (Firebase Auth)
    addedByName,    // Nombre de quien agregó
    userName,       // Nombre del usuario al que se le registró
    categoryName,   // Nombre de la categoría
    amount,         // Monto
  } = recordData;

  if (!addedBy) {
    console.log("No se encontró el campo 'addedBy' en el registro");
    return null;
  }

  try {
    // Obtener todos los perfiles EXCEPTO el del usuario que creó el registro
    const profilesSnapshot = await db
      .collection("profiles")
      .where("authUserId", "!=", addedBy)
      .get();

    if (profilesSnapshot.empty) {
      console.log("No hay otros usuarios para notificar");
      return null;
    }

    // Extraer tokens FCM válidos
    const tokens = [];
    profilesSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken && data.fcmToken.length > 0) {
        tokens.push(data.fcmToken);
        console.log(`Token encontrado para: ${data.name}`);
      }
    });

    if (tokens.length === 0) {
      console.log("No hay tokens FCM disponibles para enviar notificaciones");
      return null;
    }

    console.log(`Enviando notificación a ${tokens.length} dispositivo(s)`);

    // Construir el mensaje de notificación
    const formattedAmount = parseFloat(amount).toFixed(2);
    const notificationTitle = "Nuevo ahorro registrado";
    const notificationBody = `${addedByName || "Alguien"} agregó Bs ${formattedAmount} a ${userName || "Usuario"} por ${categoryName || "Categoría"}`;

    // Enviar notificaciones usando Firebase Admin SDK (API v1)
    // Usamos sendEachForMulticast para enviar a múltiples tokens
    const message = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        type: "new_record",
        recordId: event.params.recordId,
        userName: userName || "",
        categoryName: categoryName || "",
        amount: String(amount),
        addedByName: addedByName || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens: tokens,
    };

    const response = await messaging.sendEachForMulticast(message);

    console.log(`Notificaciones enviadas: ${response.successCount} exitosas, ${response.failureCount} fallidas`);

    // Manejar tokens inválidos (opcional: limpiarlos de Firestore)
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.log(`Error enviando a token ${idx}:`, resp.error?.message);
          // Si el error es por token inválido, marcarlo para limpieza
          if (
            resp.error?.code === "messaging/invalid-registration-token" ||
            resp.error?.code === "messaging/registration-token-not-registered"
          ) {
            failedTokens.push(tokens[idx]);
          }
        }
      });

      // Opcional: Limpiar tokens inválidos de Firestore
      if (failedTokens.length > 0) {
        console.log(`Limpiando ${failedTokens.length} tokens inválidos...`);
        const batch = db.batch();
        for (const token of failedTokens) {
          const profileQuery = await db
            .collection("profiles")
            .where("fcmToken", "==", token)
            .get();

          profileQuery.forEach((doc) => {
            batch.update(doc.ref, {
              fcmToken: null,
              tokenUpdatedAt: null,
            });
          });
        }
        await batch.commit();
        console.log("Tokens inválidos limpiados");
      }
    }

    return { success: true, sent: response.successCount };
  } catch (error) {
    console.error("Error al enviar notificaciones:", error);
    return { success: false, error: error.message };
  }
});
