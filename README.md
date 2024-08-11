First, use to create the database according to the schema.
```{bash}
cd database; sqlite3 sources.db < setup_schema.sql; cd ..
```

The user inputs the data for their reference into the `entry.toml` file.
The `so-add` script reads the file and inserts into the database.
This script can be added to the system path and mapped to a keybinding.

From the CLI it is
```{bash}
lua scripts/so-add.lua
```

The script also has the functionality of returning a json for the data and automatically creates a note markdown file for each source.
These notes can be managed in a zettelkasten or any other type of way, facilitated by the marskman lsp server.

Once the database is up, the user can use SQL to write queries
```{bash}
sqlite3 database/sources.db < "SELECT * FROM sources WHERE title LIKE '%information geometry%'"
```

You can also output the results line by line or as an html table (see `man sqlite3` for more).

You can save what is in the sources database to a json.
```{bash}
sqlite3 database/sources.db <<EOF
.mode json
.output result.json
SELECT uri FROM sources;
EOF
```

The uri (unique resource indicator) can in some cases be used to access databases for resource data.

We can request the CrossRef API
```{bash}
curl -H "Accept: application/json" "https://api.crossref.org/works/10.1007/978-3-319-56478-4"
```

or use the ISBN to launch an API request to Google Books
```{bash}
curl -X GET "https://www.googleapis.com/books/v1/volumes?q=isbn:978-3-319-56478-4"
```
