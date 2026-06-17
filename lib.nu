export def note [] {
    help note
}

# Create or edit existing note for a date.
export def "note dated" [date_target: string = "today" ] {
    let date = $date_target | date from-human | format date "%Y-%m-%d"

    let template_path = $"(get_local_path)/templates/dated.md"
    let initial_content = if ($template_path | path exists) { open $template_path } else ""

    open_note $"(get_local_path)/dated/($date).md" $initial_content
}

# Create a new note with a title.
export def "note named" [title: string] {
    let date = date now | format date "%Y-%m-%d-%H-%M-%S"
    let note_path = $"(get_local_path)/named/($date).md" 

    let template_path = $"(get_local_path)/templates/named.md"
    mut initial_content = if ($template_path | path exists) { open $template_path } else ""
    let initial_content = $"($initial_content)($in)"

    open_note $note_path $initial_content ($title | str capitalize)
}

# Search through all notes content using ripgrep.
export def "note grep" [query: string] { 
    ^rg -i $query (get_local_path)
}

# List named notes with titles matching the query.
export def "note list" [title_query: string = ""] {
    ^rg $"^# .*($title_query).*" -m 1 -i $"(get_local_path)/named" --json 
    | lines 
    | each { from json } 
    | where type == "match" 
    | get data 
    | flatten 
    | select lines_text text 
    | rename title path
    | update title { str trim | str substring 2.. }
    | sort
}

# Sync note repository.
export def "note sync" [] {
    let local_path = get_local_path
    if not ($local_path | path exists) { mkdir ($local_path) }
    cd $local_path

    if not (".git" | path exists) {
        ^git init -b main
        ^git remote add origin (get_remote_url)
        
        if (^git fetch | complete).exit_code != 0 {
            rm -rf .git
            error make {msg: "Git fetch failed. Removing changes and exiting."}
        }

        ^git-crypt unlock (get_crypt_key_path)
        ^git checkout -b main origin/main --force
    }

    let lock_file = ".git/index.lock"
    if ($lock_file | path exists) { 
        rm $lock_file 
    }

    ^git branch --set-upstream-to=origin/main main

    ^git add -A
    try { 
        ^git commit -m $"($env.USER)@(sys host | get hostname)" 
    }
    ^git pull --rebase origin main --autostash -X ours
    ^git push origin main
}

def open_note [relative_path: string, initial_content: string = "", title: string = ""] {
    let path = (get_local_path | path join $relative_path)
    let title = if ($title != "") { $"# ($title)\n\n" } else "";
    let content = $"($title)($initial_content)"
    mkdir ($path | path dirname)
    if not ($path | path exists) { $content | save $path -f }
    ^$env.EDITOR $path
}

def get_local_path [] {
    $env.NOTES_NU_LOCAL_PATH | path expand
}

def get_remote_url [] {
    $env.NOTES_NU_REMOTE_URL
}

def get_crypt_key_path [] {
    $env.NOTES_NU_CRYPT_KEY_PATH | path expand
}
