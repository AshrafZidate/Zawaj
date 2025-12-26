const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkPartnerships() {
  const usersSnapshot = await db.collection('users').get();

  console.log('=== Users with Partners ===');
  let foundPartners = false;
  usersSnapshot.forEach(doc => {
    const data = doc.data();
    const hasPartnerIds = data.partnerIds && data.partnerIds.length > 0;
    const hasPartnerId = data.partnerId;

    if (hasPartnerIds || hasPartnerId) {
      foundPartners = true;
      console.log('User:', data.fullName, '(@' + data.username + ')');
      console.log('  partnerIds:', JSON.stringify(data.partnerIds || []));
      console.log('  partnerId:', data.partnerId || 'null');
      console.log('  status:', data.partnerConnectionStatus);
      console.log('');
    }
  });

  if (!foundPartners) {
    console.log('No users have partners yet.\n');
  }

  console.log('=== All Partner Requests (Details) ===');
  const requestsSnapshot = await db.collection('partnerRequests').get();
  if (requestsSnapshot.empty) {
    console.log('No partner requests found.');
  } else {
    requestsSnapshot.forEach(doc => {
      const data = doc.data();
      console.log('Document ID:', doc.id);
      console.log('  senderId:', data.senderId);
      console.log('  senderUsername:', data.senderUsername);
      console.log('  receiverUsername:', data.receiverUsername);
      console.log('  receiverId:', data.receiverId || 'NOT SET');
      console.log('  status:', data.status);
      console.log('');
    });
  }

  process.exit(0);
}

checkPartnerships();
