const User = require('../models/User');
const bcrypt = require('bcrypt');
const salt = "$2b$05$762uRTd20ZyeQnOM7S9oHO";

const createUser = async (req, res) => {
    const d = new Date();
    var { name, username, email, password } = req.body;
    let userID =  Math.floor(Math.random() * 100).toString() + d.getTime().toString();

    const hash = bcrypt.hashSync(password, salt);
    password = hash

    const newUser = {
        userID, name, username, email, password
    }

    const user = new User(newUser);
    console.log(req.body);
    await user.save().then(() => {
        console.log('Created Account')
        res.send("Create Account")
    })
}

const signIn = async (req, res) => {
    const d = new Date();
    var { email, password } = req.body;

    const hash = bcrypt.hashSync(password, salt);
    password = hash

    const user = User.findOne({ 'email': email }).then(
        user => {
            if(user.password==hash){
                res.send('Sign in Successful');
            }
            else{
                res.send('Password is Wrong');
            }
        }
    ).catch((err) => {
        console.log(err)
        res.send('Account do not exists');
    })

    console.log(user);
}

module.exports = { createUser, signIn };
