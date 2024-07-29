local driver = require('luasql.sqlite3')
local toml = require('toml')

local soorg_directory = "."

local env = assert (driver.sqlite3())
local con = assert (env:connect(soorg_directory .. '/database/sources.db'))

local function get_last_insert_rowid()
    local cursor = assert (con:execute("SELECT last_insert_rowid() AS id;"))
    local row = cursor:fetch({}, "a")
    cursor:close()
    return tonumber(row.id)
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

local function insert_source(title, year, uri, file, note, authors)
    assert (con:execute(string.format([[
        INSERT INTO sources (title, year, uri, file, note)
        VALUES ('%s', %d, '%s', '%s', '%s');
    ]], title, year, uri, file, note)
    ))

    local source_id = get_last_insert_rowid()

    for _, author in ipairs(authors) do
        local author_id = insert_author(author.first_name, author.last_name)

        assert (con:execute(string.format([[
            INSERT INTO source_authors (source_id, author_id)
            VALUES (%d, %d);
        ]], source_id, author_id)))
    end
end

local function process_toml_file(file_path)
    local file, err = io.open(file_path, 'r')
    if not file then
        error('Failed to open file: ' .. (err or 'Unknown error'))
    end

    local toml_data = file:read('*a')
    file:close()
    local data = toml.parse(toml_data)

    local note = 'note' .. os.date('%Y%m%d%H%M%S') .. '_' .. tostring(math.random(10^5, 10^6 - 1))
    os.execute(string.format('mkdir "%s"', soorg_directory .. '/notes/' .. note))

    insert_source(
        data.source.title,
        data.source.year,
        data.source.uri,
        data.source.file,
        note,
        data.author
    )
end

process_toml_file(soorg_directory .. '/database/entry.toml')

con:close()
env:close()

