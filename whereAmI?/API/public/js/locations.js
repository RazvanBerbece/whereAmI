const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

// Holds all crowdsourced locations
let locations = [];

app.use(cors());

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.post('/locations', (req, res) => {
    
    const new_location = req.body;
    console.log(new_location);
    
    locations.push(new_location);
    
    res.send('Location added to database.')
});

app.listen(port, () => console.log('Server listening on port 3000!'));
