require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cookieParser = require('cookie-parser');
const { router: indexRoutes } = require('./routes/indexRoutes.js');

const app = express();

app.set('view engine', 'ejs');
app.set('trust proxy', 1);
app.use(express.static('public'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

app.use('/', indexRoutes);

mongoose.connect(process.env.MONGODB_URI)
    .then(() => {
        console.log("MongoDB Connected");
        app.listen(process.env.PORT, () => {
            console.log("Listening on PORT: " + process.env.PORT);
        });
    })
    .catch((err) => {
        console.log("MongoDB did not connect:", err.message);
    });

module.exports = app;