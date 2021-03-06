/* -------------- Requires & Port init -------------- */

const express = require('express');

const app = express();

const bodyParser = require('body-parser');
const cors = require('cors');

/* -------------- Firebase Config & Init -------------- */

var firebase = require('firebase');

var config = {
  apiKey: "AIzaSyDtFkJomvWdTfQmpHdc9l_iPPK7o_dmMyU",
  authDomain: "whereami-275517.firebaseapp.com",
  databaseURL: "https://whereami-275517.firebaseio.com",
  projectId: "whereami-275517",
  storageBucket: "whereami-275517.appspot.com",
  messagingSenderId: "792933508906",
  appId: "1:792933508906:web:f3dcd06f517a0549d2e053"
};

firebase.initializeApp(config);

const functions = require('firebase-functions');

/* -------------- Saved variables (per request) -------------- */

let locations = [];
var database = firebase.database();

/* -------------- Cors() amd body-parser -------------- */

app.use(cors());

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

/* -------------- CRUD -------------- */

app.get('/', (req, res) => { // Testing server is listening
    res.json({"message": "Hello, you accessed the server.", "result": true});
});

app.post('/locations', (req, res) => { // Saving a location in the local list and in the Firebase Cloud
    
    const new_location = req.body;

    console.log(new_location);

    var long = new_location.longitude;
    var lat = new_location.latitude;
    var name = new_location.name;
    var rad = new_location.radius;

    if (isFloat(long) == true && isFloat(lat) == true && isFloat(rad) == true && name.length != 0 && name !== null) {

          console.log(new_location);
          
          var ref = database.ref();
          var child = ref.child("locations");

          child.push({
            name: name,
            longitude: long,
            latitude: lat,
            radius: rad
          });
    
      locations.push(new_location);
    }
    else { console.log("Input seems to be wrong. Check it and try again."); }

});

app.get('/locations', (req, res) => { // Getting the list of all locations

  gotLocations = [];

  var locRef = database.ref('locations');
  locRef.on('value', function(snapshot) {
    snapshot.forEach(function(childSnapshot) {
      var childData = childSnapshot.val();
      gotLocations.push(childData);
    });
  });

  res.json(gotLocations);

});

/* -------------- JS Helper Functions -------------- */

/* 
  Checks if the number can be parsed as float,
  For input sanity check purposes.
*/
function isFloat(input) {
  
  var result = parseFloat(input);

  if ((isNaN(result)) == false) {
    return true;
  }
  
  return false;
}

/* -------------- Uploading to Firebase Functions  -------------- */

exports.app = functions.https.onRequest(app);
