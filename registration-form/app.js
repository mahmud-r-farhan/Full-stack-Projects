const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');

const app = express();
const port = 3000;

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/UserData');

// Define a schema
const userSchema = new mongoose.Schema({
    name: String,
    email: String,
    password: String,
    phone: String
});

// Create a model
const User = mongoose.model('User', userSchema);

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files
app.use(express.static('public'));

// Handle form submission
app.post('/register', async (req, res) => {
    const newUser = new User({
        name: req.body.name,
        email: req.body.email,
        password: req.body.password,
        phone: req.body.phone
    });

    try {
        await newUser.save();
        res.send('Successfully registered!');
    } catch (err) {
        res.send(err);
    }
});

    // command
//  cd registrations-form
// node app.js

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
