var massive = require("massive");
var fs = require("fs");
var _ = require("underscore")._;
var async = require("async");

var srcDir = __dirname + "/build/src/";
var tableDir = srcDir + "tables/"
var indexDir = srcDir + "indexes/"
var functionDir = srcDir + "functions/"
var distFile = __dirname + "/build/dist/pg_auth.sql";

var DB = "pg_auth";


var functionSql = function(){
  var sqlFiles = [];
  var files = fs.readdirSync(functionDir);
  _.each(files, function(file){
    if(file.indexOf(".sql") > 0){
      var sql = fs.readFileSync(functionDir + file, {encoding : "utf-8"});
      sqlFiles.push(sql);     
    }
  });
  sqlFiles.push("select 'functions installed' as result;");
  return sqlFiles.join("\r\n\r\n");
};

var tableSql = function(){
  var sqlFiles = [];
  var files = fs.readdirSync(tableDir);
  _.each(files, function(file){
    if(file.indexOf(".sql") > 0){
      var sql = 
      sqlFiles.push(fs.readFileSync(tableDir + file, {encoding : "utf-8"}));
    }
  });
  sqlFiles.push("select 'tables installed' as result;");
  
  //add the foreign keys
  var fks = fs.readFileSync(indexDir + "foreign_keys.sql", {encoding : "utf-8"});
  sqlFiles.push(fks);

  return sqlFiles.join("\r\n\r\n");
};


exports.build = function(){
  var buildScript = [];

  buildScript.push("-- built on " + new Date());

  //start off the transaction
  buildScript.push("BEGIN;");

  //grab the init file
  var initSql = fs.readFileSync(srcDir + "init.sql", {encoding : "utf-8"});
  buildScript.push(initSql);

  //tables
  buildScript.push(tableSql());

  //functions
  buildScript.push(functionSql());

  //end tx
  buildScript.push("COMMIT;");

  var sql = buildScript.join("\r\n\r\n");
  //write it out
  fs.writeFileSync(distFile,sql);
 
  return sql;
};

exports.install = function(){
  var self = this;
  massive.connect({db : DB}, function(err,db){
    var sql = self.build();
    db.run(sql);
  });
};


this.install();