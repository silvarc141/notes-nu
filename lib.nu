let notes_dir = $env.NOTES_NU_LOCAL_PATH | path expand
let remote_url = $env.NOTES_NU_REMOTE_URL
# let crypt_key_path = $env.NOTES_NU_CRYPT_KEY_PATH

export def note [] {}

export def "note dated" [date_target: string] {
    let date = $date_target | date from-human | format date "%Y-%m-%d"
    open_note $"($notes_dir)/dated/($date).md"
}

export def "note named" [title: string] {
    let date = date now | format date "%Y-%m-%d-%H-%M-%S"
    open_note $"($notes_dir)/named/($date).md" $title
}

export def "note grep" [query: string] { 
    ^rg -i $query $notes_dir
}

export def "note list" [query: string] {
    ^rg $"^# .*($query).*" -m 1 $notes_dir --json 
    | lines 
    | each { from json } 
    | where type == "match" 
    | get data 
    | enumerate 
    | flatten 
    | flatten 
    | select index lines_text text 
    | rename index title path
}

export def "note sync" [] {
    if not ($notes_dir | path exists) { mkdir $notes_dir }
    cd $notes_dir

    if not (".git" | path exists) {
        git init -b main
        git remote add origin $remote_url
        
        if (git fetch | complete).exit_code != 0 {
            rm -rf .git
            error make {msg: "Git fetch failed. Removing changes and exiting."}
        }
        
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
    let path = ($notes_dir | path join $file)
    let content = if ($title != "") { $"# ($title)\n\n" } else "";
    if not ($path | path exists) { $content | save $path }
    ^$env.EDITOR $path
}
