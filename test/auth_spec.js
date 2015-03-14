var assert = require("assert");
var helpers = require("./helpers");

var user = {};

describe("Authentication", function() {
  before(function (done) {
    helpers.initDb(function(err,res){
      helpers.register({email : "test@test.com", password : "password", confirm : "password"}, function(err,res){
        user = res;
        done();
      });
    });
  });

  describe("valid authentication", function(){
    var authResult = {};
    before(function(done){
      helpers.db.membership.authenticate(["test@test.com","password", "local", "127.0.0.1"],function(err,res){

        authResult = res[0];
        done();
      });
    });
    it("is successful", function(){
      assert.ok(authResult.success);
    });
    it("returns a session_id", function(){
      assert.ok(authResult.session_id);
    });
    it("returns a user record", function(){
      assert.ok(authResult.member_id);
    });
  });

  describe("invalid authentication", function(){
    var authResult = {};
    before (function(done){
      helpers.db.membership.authenticate(["test@test.com","poop", "local", "127.0.0.1"], function(err,res){
        authResult = res[0];
        done();
      });
    });
    it("is not successful", function(){
      assert.ok(!authResult.success);
    });
    it("provides a message", function(){
      assert.equal(authResult.message, "Invalid username or password");
    });
  });

  describe("Token Authentication", function(){
    var authResult = {};
    before(function(done) {
      helpers.db.membership.authenticate([null,user.email_validation_token, "token", "127.0.0.1"], function(err,res){
        authResult = res[0];
        done();
      });
    });
    it("is successful", function(){
      assert.ok(authResult.success);
    });
    it("returns a session_id", function(){
      assert.ok(authResult.session_id);
    });
    it("returns a member_id", function(){
      assert.ok(authResult.member_id);
    });
  });

  describe("3rd Party Authentication", function(){
    var authResult = {};
    before(function(done) {
      helpers.db.membership.add_login([user.email, 'some_url', 'some token', 'some service'], function(err,res){
        assert.ok(res[0].success, res[0].message);
        helpers.db.membership.authenticate(['some_url','some token','some service', "127.0.0.1"], function(err,res){
          authResult = res[0];
          done();
        });

      });
    });
    it('adds a login for the member', function(done){
      helpers.db.query("select * from membership.logins", [], function(err,res){
        assert.equal(res.length,3);
        done();
      });
    });
    it("is successful", function(){
      assert.ok(authResult.success);
    });
    it("returns a session_id", function(){
      assert.ok(authResult.session_id);
    });
    it("returns a member_id", function(){
      assert.ok(authResult.member_id);
    });
  });


});
