const mongoose = require('mongoose')
async function connect(){
    try{
        await mongoose.connect('mongodb+srv://DKER:Phuong2003@cluster0.n8bg2.mongodb.net/?retryWrites=true&w=majority');
        console.log("Connect Succesfully");
    } catch(error){
        console.log("Connect fail")
    }
}
module.exports = {connect}