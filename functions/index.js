const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');

admin.initializeApp();

exports.notifyAllUsers = functions.database
  .ref('/yourDataPath/{childId}')  // Replace with your actual data path
  .onWrite((change, context) => {
    // OneSignal notification content
    const notificationContent = JSON.stringify({
      app_id: "4d56fe0b-b1a7-4f4b-b6d6-6d5c4829f746",  // Replace with your OneSignal App ID
      included_segments: ["All"],
      headings: {"en": "Database Updated"},
      contents: {"en": "There's new content in your app!"}
    });

    const options = {
      hostname: 'onesignal.com',
      path: '/api/v1/notifications',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'mapvj73c7eet5sqz6yr2nnosr'  // Replace with your OneSignal REST API key
      }
    };

    const req = https.request(options, (res) => {
      let response = '';
      res.on('data', (chunk) => { response += chunk; });
      res.on('end', () => { console.log('OneSignal Response:', response); });
    });

    req.on('error', (e) => { console.error('OneSignal Error:', e); });
    req.write(notificationContent);
    req.end();

    return null;
  });
