var assert = require("assert");
var helpers = require("./helpers");

var newId = 0;

describe("Notes", function(){
  before(function(done){
    helpers.initDb(function(err,res){
      helpers.register({email : "test@test.com",password : "password",confirm : "password"},function(err,res){
        assert.ok(res.success, "Can't add user for some reason");
        newId = res.new_id;
        done();
      });
    });
  });

  //add a note to the user... make sure it comes back to us
  describe("adding a note", function(){
    var succeeded = false;
    var user ={};
    before(function(done){
      helpers.db.membership.add_note(['test@test.com','This is a Note'], function(err,res){
        succeeded = res[0].succeeded;
        helpers.db.membership.get_member(newId, function(err,res){
          user = res[0];
          done();
        });
      });
    });

    it("succeeds", function(){
      assert.ok(succeeded);
    });
    it("added the note to the user", function(){
      assert.equal(user.notes.length, 1);
      assert.equal(user.notes[0].note, "This is a Note");
    });

  });
});
