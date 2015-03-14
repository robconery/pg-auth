var massive = require("massive");
var builder = require("../../index");



var Helpers = function(){
  this.db={};
  this.initDb = function(next){

    var sql = builder.build();
    massive.connect({db : "pg_auth"}, function(err,res){
      this.db = res;
      this.db.run(sql, [], next);
    }.bind(this));
  };

  this.register = function(args, next){
    this.db.membership.register([args.email, args.password, args.confirm], function(err,res){
      next(err,res[0])
    });
  };

};

module.exports = new Helpers();


