var assert = require("assert");
var helpers = require("./helpers");

var newId = 0;

describe("Status checks", function(){
  before(function(done){
    helpers.initDb(function(err,res){
      helpers.register({email : "test@test.com",password : "password",confirm : "password"},function(err,res){
        assert.ok(res.success, "Can't add user for some reason");
        newId = res.new_id;
        done();
      });
    });
  });
  describe("activating a user", function(){
    var user = {};
    before(function(done){
      helpers.db.membership.activate_member('test@test.com', function(err,res1){
        helpers.db.membership.get_member(newId, function(err,res2){
          user = res2[0];
          done();
        });
      });
    });
    it("loads up the user", function(){
      assert.ok(user.status == "Active");
    });

    it("allows the user to login", function(){
      assert.ok(user.can_login);
    });
  });
  describe("suspending a user", function(){
    var user = {};
    before(function(done){
      helpers.db.membership.suspend_member(['test@test.com','Testing Suspension'], function(err,res1){
        helpers.db.membership.get_member(newId, function(err,res2){
          user = res2[0];
          done();
        });
      });
    });
    it("sets the status as suspended", function(){
      assert.equal(user.status, "Suspended");
    });

    it("adds message to log entry", function(){
      assert.ok(user.logs[user.logs.length-1].entry.indexOf("Testing Suspension") > -1);
    })
    it("dissallows login", function(){
      assert.ok(!user.can_login);
    });
  });
  describe("banning a user", function(){
    var user = {};
    before(function(done){
      helpers.db.membership.ban_member(['test@test.com','Testing Ban'], function(err,res1){
        helpers.db.membership.get_member(newId, function(err,res2){
          user = res2[0];
          done();
        });
      });
    });
    it("sets the status as banned", function(){
      assert.equal(user.status, "Banned");
    });
    it("adds message to log entry", function(){
      assert.ok(user.logs[user.logs.length-1].entry.indexOf("Testing Ban") > -1);
    })
    it("dissallows login", function(){
      assert.ok(!user.can_login);
    });
  });
  describe("locking a user", function(){
    var user = {};
    before(function(done){
      helpers.db.membership.lock_member(['test@test.com'], function(err,res1){
        helpers.db.membership.get_member(newId, function(err,res2){
          user = res2[0];
          done();
        });
      });
    });
    it("sets the status as locked", function(){
      assert.equal(user.status, "Locked");
    });
    it("dissallows login", function(){
      assert.ok(!user.can_login);
    });
  });
});
