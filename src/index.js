const express = require('express');
const path = require('path');
const morgan = require('morgan');
const route = require('./routes');
const db = require('./config/db.js');

const app = express();

//Database Connect
db.connect()

//HTTP Logger
app.use(morgan('dev'));

//Jsontify App
app.use(express.json())

//Route App 
route(app)

//Template Engine
app.use(express.json());

const port = 3000;
app.listen(port, () => {
    console.log(`Example app listening on port ${port}`);
});
