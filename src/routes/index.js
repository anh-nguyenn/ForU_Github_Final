const userRouter = require('./user.js');

function route(app) {
    app.use('/user', userRouter);
}

module.exports = route;
