/* -------------- Requires & Port init -------------- */

const express = require('express');

const app = express();
const port = 3000;

const bodyParser = require('body-parser');
const cors = require('cors');

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

app.post('/locations', (req, res) => { // Saving a location in the local list
    const new_location = req.body;
    console.log(new_location);
    
    locations.push(new_location);
    
    res.send("Added to database.");
});

app.get('/locations', (req, res) => { // Getting the list of all locations
	res.json(locations);
})

/* -------------- Listening -------------- */

app.listen(port, () => console.log(`Server listening on ${port} ...`));