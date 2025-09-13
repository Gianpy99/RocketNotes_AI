import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Family invitation notification
export const sendFamilyInvitationNotification = functions.firestore
  .document('families/{familyId}/invitations/{invitationId}')
  .onCreate(async (snap, context) => {
    const invitation = snap.data();
    const { familyId } = context.params;
    
    try {
      // Get family information
      const familyDoc = await admin.firestore()
        .collection('families')
        .doc(familyId)
        .get();
      
      if (!familyDoc.exists) {
        console.error('Family not found:', familyId);
        return;
      }
      
      const family = familyDoc.data();
      
      // Get inviter information
      const inviterDoc = await admin.firestore()
        .collection('users')
        .doc(invitation.inviterId)
        .get();
      
      const inviterName = inviterDoc.exists 
        ? inviterDoc.data()?.name || 'Someone'
        : 'Someone';
      
      // Get invitee's FCM token
      const inviteeDoc = await admin.firestore()
        .collection('users')
        .where('email', '==', invitation.inviteeEmail)
        .limit(1)
        .get();
      
      if (inviteeDoc.empty) {
        console.log('Invitee not found, will send when they sign up');
        return;
      }
      
      const inviteeData = inviteeDoc.docs[0].data();
      const fcmToken = inviteeData.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token for invitee');
        return;
      }
      
      // Send notification
      const message = {
        token: fcmToken,
        notification: {
          title: 'Family Invitation',
          body: `${inviterName} invited you to join "${family?.name}" family`
        },
        data: {
          type: 'family_invitation',
          familyId: familyId,
          invitationId: snap.id
        }
      };
      
      await admin.messaging().send(message);
      console.log('Family invitation notification sent');
      
    } catch (error) {
      console.error('Error sending family invitation notification:', error);
    }
  });

// Shared note notification
export const sendSharedNoteNotification = functions.firestore
  .document('shared_notes/{noteId}')
  .onCreate(async (snap, context) => {
    const sharedNote = snap.data();
    
    try {
      // Get family members
      const familyDoc = await admin.firestore()
        .collection('families')
        .doc(sharedNote.familyId)
        .get();
      
      if (!familyDoc.exists) {
        console.error('Family not found:', sharedNote.familyId);
        return;
      }
      
      const family = familyDoc.data();
      const memberIds = family?.memberIds || [];
      
      // Get sharer information
      const sharerDoc = await admin.firestore()
        .collection('users')
        .doc(sharedNote.sharedBy)
        .get();
      
      const sharerName = sharerDoc.exists 
        ? sharerDoc.data()?.name || 'Someone'
        : 'Someone';
      
      // Get FCM tokens for family members (except sharer)
      const userDocs = await admin.firestore()
  .collection('users')
  .where('__name__', 'in', memberIds.filter((id: string) => id !== sharedNote.sharedBy))
  .get();
      
      const tokens = userDocs.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token);
      
      if (tokens.length === 0) {
        console.log('No FCM tokens found for family members');
        return;
      }
      
      // Send notifications
      const message = {
        tokens: tokens,
        notification: {
          title: 'Note Shared',
          body: `${sharerName} shared a note: "${sharedNote.title}"`
        },
        data: {
          type: 'note_shared',
          noteId: context.params.noteId,
          familyId: sharedNote.familyId
        }
      };
      
      await admin.messaging().sendEachForMulticast(message);
      console.log('Shared note notifications sent');
      
    } catch (error) {
      console.error('Error sending shared note notification:', error);
    }
  });

// Note comment notification
export const sendCommentNotification = functions.firestore
  .document('shared_notes/{noteId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const { noteId } = context.params;
    
    try {
      // Get shared note information
      const noteDoc = await admin.firestore()
        .collection('shared_notes')
        .doc(noteId)
        .get();
      
      if (!noteDoc.exists) {
        console.error('Shared note not found:', noteId);
        return;
      }
      
      const sharedNote = noteDoc.data();
      
      // Get commenter information
      const commenterDoc = await admin.firestore()
        .collection('users')
        .doc(comment.authorId)
        .get();
      
      const commenterName = commenterDoc.exists 
        ? commenterDoc.data()?.name || 'Someone'
        : 'Someone';
      
      // Get family members (except commenter)
      const familyDoc = await admin.firestore()
        .collection('families')
        .doc(sharedNote?.familyId)
        .get();
      
      if (!familyDoc.exists) {
        console.error('Family not found:', sharedNote?.familyId);
        return;
      }
      
      const family = familyDoc.data();
  const memberIds = (family?.memberIds || []).filter((id: string) => id !== comment.authorId);
      
      if (memberIds.length === 0) {
        console.log('No other family members to notify');
        return;
      }
      
      // Get FCM tokens
      const userDocs = await admin.firestore()
        .collection('users')
        .where('__name__', 'in', memberIds)
        .get();
      
      const tokens = userDocs.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token);
      
      if (tokens.length === 0) {
        console.log('No FCM tokens found for family members');
        return;
      }
      
      // Send notifications
      const message = {
        tokens: tokens,
        notification: {
          title: 'New Comment',
          body: `${commenterName} commented on "${sharedNote?.title}"`
        },
        data: {
          type: 'note_comment',
          noteId: noteId,
          commentId: snap.id,
          familyId: sharedNote?.familyId
        }
      };
      
      await admin.messaging().sendEachForMulticast(message);
      console.log('Comment notifications sent');
      
    } catch (error) {
      console.error('Error sending comment notification:', error);
    }
  });

// Family member activity notification
export const sendActivityNotification = functions.firestore
  .document('families/{familyId}/activity/{activityId}')
  .onCreate(async (snap, context) => {
    const activity = snap.data();
    const { familyId } = context.params;
    
    try {
      // Skip certain activity types that don't need notifications
      const skipTypes = ['member_active', 'member_inactive'];
      if (skipTypes.includes(activity.type)) {
        return;
      }
      
      // Get family members
      const familyDoc = await admin.firestore()
        .collection('families')
        .doc(familyId)
        .get();
      
      if (!familyDoc.exists) {
        console.error('Family not found:', familyId);
        return;
      }
      
      const family = familyDoc.data();
  const memberIds = (family?.memberIds || []).filter((id: string) => id !== activity.userId);
      
      if (memberIds.length === 0) {
        console.log('No other family members to notify');
        return;
      }
      
      // Get actor information
      const actorDoc = await admin.firestore()
        .collection('users')
        .doc(activity.userId)
        .get();
      
      const actorName = actorDoc.exists 
        ? actorDoc.data()?.name || 'Someone'
        : 'Someone';
      
      // Get FCM tokens
      const userDocs = await admin.firestore()
        .collection('users')
        .where('__name__', 'in', memberIds)
        .get();
      
      const tokens = userDocs.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token);
      
      if (tokens.length === 0) {
        console.log('No FCM tokens found for family members');
        return;
      }
      
      // Generate notification content based on activity type
      let title = 'Family Activity';
      let body = `${actorName} performed an action`;
      
      switch (activity.type) {
        case 'member_joined':
          title = 'New Family Member';
          body = `${actorName} joined the family`;
          break;
        case 'member_left':
          title = 'Family Member Left';
          body = `${actorName} left the family`;
          break;
        case 'note_created':
          title = 'New Note';
          body = `${actorName} created a new note`;
          break;
        case 'note_shared':
          title = 'Note Shared';
          body = `${actorName} shared a note with the family`;
          break;
        default:
          body = `${actorName} ${activity.description || 'performed an action'}`;
      }
      
      // Send notifications
      const message = {
        tokens: tokens,
        notification: {
          title: title,
          body: body
        },
        data: {
          type: 'family_activity',
          familyId: familyId,
          activityId: snap.id,
          activityType: activity.type
        }
      };
      
      await admin.messaging().sendEachForMulticast(message);
      console.log('Activity notifications sent');
      
    } catch (error) {
      console.error('Error sending activity notification:', error);
    }
  });

// Update user FCM token
export const updateFCMToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { token } = data;
  const userId = context.auth.uid;
  
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        fcmToken: token,
        fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    
    console.log('FCM token updated for user:', userId);
    return { success: true };
    
  } catch (error) {
    console.error('Error updating FCM token:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update FCM token');
  }
});