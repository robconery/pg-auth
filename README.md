## A Bit of Crazy

I'm fairly certain that the existence of this repo will cause anxiety. It's just a thought exercise - people have asked, so here it is.

This is the **Postgres Authentication stuff** - meaning it's a full authentication system in a box, in your DB. I flipped out one weekend and decided to see if I could do it... I could, so here it is. 

Still a bit raw, but tests are passing nicely. Still need to work on a few things.

## Installation

I tried to make everything as self-contained as I could. So, to install this just crack open `index.js` and set `DB` to whatever local database you want to use.

And then...

```
npm install
node index.js
```

This will execute a bulk SQL transaction against your database and will:

 - Create a schema called "membership"
 - Install `pgcrypto` for hashing passwords
 - Drop in the schema, tables, functions etc needed for this crazy

## Development

If you want to play around, the test db is called `pg_auth` and I build it on the fly. You can see all the scripts in the `build/src` directory - these get built and dropped into `build/dist`. If all you want is to check stuff out just install as above and have a good time.

## This is Supposed To Be Fun

I like seeing what Postgres can do, and I'm not the world's best programmer so if you see some things that are interesting, have some fun.
