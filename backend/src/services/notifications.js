async function createNotification(models, notification) {
  try {
    return await models.Notification.create(notification);
  } catch (error) {
    // Unique event keys make retries safe when the pickup operation succeeded
    // but its caller needs to retry the notification write.
    if (error.code === 11000) return null;
    console.error(JSON.stringify({
      event: 'notification_persistence_failure',
      type: notification.type,
      errorCategory: error.name || 'database_error',
    }));
    return null;
  }
}

function pickupNotification({ userId, pickupId, type, title, message, eventKey }) {
  return {
    userId,
    type,
    title,
    message,
    relatedPickupId: pickupId,
    eventKey,
  };
}

module.exports = { createNotification, pickupNotification };
