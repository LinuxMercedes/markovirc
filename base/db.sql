CREATE TABLE "users"(
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "hostmask" TEXT,
    "isadmin" INTEGER DEFAULT (0)
); CREATE TABLE "channels" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "name" TEXT
); CREATE TABLE "sources"(
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "type" INTEGER,
    "channelid" INTEGER,
    "userid" INTEGER
); CREATE TABLE "text" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "sourceid" INTEGER,
    "time" INTEGER,
    "text" TEXT
); CREATE TABLE "words" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "word" TEXT
); CREATE TABLE "chains" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "wordid" INTEGER,
    "textid" INTEGER,
    "nextwordid" INTEGER DEFAULT (-1)
);
