export def note [] {
    help note
}

export def "note dated" [date_target: string = "today" ] {
    let date = $date_target | date from-human | format date "%Y-%m-%d"
    open_note $"(get_local_path)/dated/($date).md"
}

export def "note named" [title: string] {
    let date = date now | format date "%Y-%m-%d-%H-%M-%S"
    open_note $"(get_local_path)/named/($date).md" $title
}

export def "note grep" [query: string] { 
    ^rg -i $query get_local_path
}

export def "note list" [query: string = ""] {
    ^rg $"^# .*($query).*" -m 1 -i $"(get_local_path)/named" --json 
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

export def "note sync" [] {
    if not (get_local_path | path exists) { mkdir get_local_path }
    cd get_local_path

    if not (".git" | path exists) {
        git init -b main
        git remote add origin (get_remote_url)
        
        if (git fetch | complete).exit_code != 0 {
            rm -rf .git
            error make {msg: "Git fetch failed. Removing changes and exiting."}
        }

        git-crypt unlock (get_crypt_key_path)
        git checkout -b main origin/main --force
    }

    let lock_file = ".git/index.lock"
    if ($lock_file | path exists) { 
        rm $lock_file 
    }

    git branch --set-upstream-to=origin/main main

    git add -A
    git commit -m $"($env.USER)@(sys host | get hostname)"
    git pull --rebase origin main --autostash -X ours
    git push origin main
}

def open_note [file: string, title: string = ""] {
    let path = (get_local_path | path join $file)
    let content = if ($title != "") { $"# ($title)\n\n" } else "";
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
