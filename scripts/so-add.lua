local driver = require('luasql.sqlite3')
local toml = require('toml')

local soorg_directory = "."

local function initialize_database()
    -- Check if the database file exists
    local file = io.open(soorg_directory .. '/database/sources.db', 'r')
    if file == nil then
        -- Create database if it doesn't exist
        os.execute(string.format('sqlite3 %s/database/sources.db < %s/database/setup_schema.sql', soorg_directory, soorg_directory))
        print("Database created and schema applied.")
    else
        file:close()
    end
end

initialize_database()

local env = assert (driver.sqlite3())
local con = assert (env:connect(soorg_directory .. '/database/sources.db'))

local function get_last_insert_rowid()
    local cursor = assert (con:execute("SELECT last_insert_rowid() AS id;"))
    local row = cursor:fetch({}, "a")
    cursor:close()
    return tonumber(row.id)
end

local function get_source_id(title, year, uri)
    local cursor = assert(con:execute(string.format([[
        SELECT id FROM sources
        WHERE title = '%s' AND year = %d AND uri = '%s';
    ]], title, year, uri)))
    local row = cursor:fetch({}, "a")
    cursor:close()
    return row and tonumber(row.id)
end

local function get_author_id(first_name, last_name)
    local cursor = assert (con:execute(string.format([[
        SELECT id FROM authors
        WHERE first_name = '%s' AND last_name = '%s';
    ]], first_name, last_name)
    ))
    local row = cursor:fetch({}, "a")
    cursor:close()
    return row and tonumber(row.id)
end

local function insert_author(first_name, last_name)
    local author_id = get_author_id(first_name, last_name)
    if not author_id then
        assert(con:execute(string.format([[
            INSERT INTO authors (first_name, last_name)
            VALUES ('%s', '%s');
        ]], first_name, last_name)))
        author_id = get_last_insert_rowid()
    end
    return author_id
end

-- check for: source and authors should be unique
local function association_exists(source_id, author_id)
    local cursor = assert(con:execute(string.format([[
        SELECT 1 FROM source_authors
        WHERE source_id = %d AND author_id = %d;
    ]], source_id, author_id)))
    local row = cursor:fetch()
    cursor:close()
    return row ~= nil
end

local function insert_source(title, year, uri, file, note, authors)
    -- add source if not already present
    local source_id = get_source_id(title, year, uri)
    if not source_id then
        assert(con:execute(string.format([[
            INSERT INTO sources (title, year, uri, file, note)
            VALUES ('%s', %d, '%s', '%s', '%s');
        ]], title, year, uri, file, note)))
        source_id = get_last_insert_rowid()
    else
        return source_id
    end
    -- add source and author to junction table if not already present
    for _, author in ipairs(authors) do
        local author_id = insert_author(author.first_name, author.last_name)
        -- Check if the association already exists
        if not association_exists(source_id, author_id) then
            assert(con:execute(string.format([[
                INSERT INTO source_authors (source_id, author_id)
                VALUES (%d, %d);
            ]], source_id, author_id)))
        end
    end
end

-- add entries from toml to sources database (without repeats)
local function process_toml_file(file_path)
    local file, err = io.open(file_path, 'r')
    if not file then
        error('Failed to open file: ' .. (err or 'Unknown error'))
    end

    local toml_data = file:read('*a')
    file:close()
    local data = toml.parse(toml_data)


    for _, source in ipairs(data.source) do
        local note = 'note' .. os.date('%Y%m%d%H%M%S') .. '_' .. tostring(math.random(10^5, 10^6 - 1))
        os.execute(string.format('mkdir "%s"', soorg_directory .. '/notes/' .. note))

        insert_source(
            source.title,
            source.year,
            source.uri,
            source.file,
            note,
            source.author
        )
    end
end


-- Function to export sources to JSON using a Bash command
local function export_sources_to_json()
    local cmd = string.format(
        'sqlite3 %s/database/sources.db -json "SELECT * FROM sources;" > %s/database/sources.json',
        soorg_directory, soorg_directory
    )
    os.execute(cmd)
    print("Data exported to sources.json.")
end


process_toml_file(soorg_directory .. '/database/entry.toml')
export_sources_to_json()

con:close()
env:close()

-- echo '' | fzf --print-query --preview "cat database/sources.json | jq {q}"

