//
// Create default users schema and initialize with some data for tsting
//
db = db.getSiblingDB('users');
db.users.insertMany([
    {name: 'alan', password: 'password', email: 'alan@foo.com'},
    {name: 'ben', password: 'password', email: 'ben@foo.com'}
]);

// unique index on the name
db.users.createIndex(
    {name: 1},
    {unique: true}
);
