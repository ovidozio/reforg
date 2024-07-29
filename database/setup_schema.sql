CREATE TABLE sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    year INTEGER,
    uri TEXT UNIQUE,
    file TEXT,
    note TEXT
);

CREATE TABLE authors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT,
    last_name TEXT
);

CREATE TABLE source_authors (
    source_id INTEGER,
    author_id INTEGER,
    FOREIGN KEY (source_id) REFERENCES sources(id),
    FOREIGN KEY (author_id) REFERENCES authors(id),
    PRIMARY KEY (source_id, author_id)
);

