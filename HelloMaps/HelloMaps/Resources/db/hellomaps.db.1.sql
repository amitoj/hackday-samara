PRAGMA auto_vacuum = 1;

CREATE TABLE friends (
    _id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    is_user INTEGER DEFAULT 0,
    phone TEXT,
    radius INTEGER,
    latitude REAL,
    longitude REAL,
    status TEXT,
    type INTEGER DEFAULT 0,
    photo_url TEXT
);