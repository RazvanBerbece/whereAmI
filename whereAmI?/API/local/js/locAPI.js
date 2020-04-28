/* -------------- Requires & Port init -------------- */

const express = require('express');

const app = express();
const port = 3000;

const bodyParser = require('body-parser');
const cors = require('cors');

var firebase = require('firebase');

/*
var config = {
  apiKey: "AIzaSyDtFkJomvWdTfQmpHdc9l_iPPK7o_dmMyU",
  authDomain: "whereami-275517.firebaseapp.com",
  databaseURL: "https://whereami-275517.firebaseio.com",
  projectId: "whereami-275517",
  storageBucket: "whereami-275517.appspot.com",
  messagingSenderId: "792933508906",
  appId: "1:792933508906:web:f3dcd06f517a0549d2e053"
};
*/

/* -------------- Saved variables (per request) -------------- */

let locations = [];

/* -------------- Cors() amd body-parser -------------- */

app.use(cors());

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

/* -------------- CRUD -------------- */

app.get('/', (req, res) => { // Testing server is listening
    res.send('Server listening ...')
});

app.post('/locations', async (req, res) => { // Saving a location in the local list
    
    const new_location = req.body;
    console.log(new_location);

    //const snapshot = await admin.database.ref('/locations').push(new_location);
    
    locations.push(new_location);
    
    res.send("Added to database.");
});

app.get('/locations', (req, res) => { // Getting the list of all locations
	res.json(locations);
})

/* -------------- Listening -------------- */

// firebase.initializeApp(config);
app.listen(port, () => console.log('Server listening on port 3000!'));

