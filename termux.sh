# Run with something like this:
# . $(curl -s https://raw.githubusercontent.com/silvarc141/notes-nu/main/termux.sh)

# Other optional setup:
# termux-change-repo
# pkg upgrade -y
# chsh nu

pkg install nushell git git-crypt ripgrep 
nu -c '
let lib = http get https://raw.githubusercontent.com/silvarc141/notes-nu/main/lib.nu
let dir = $nu.user-autoload-dirs | first
mkdir $dir
$lib o> ($dir | path join "notes.nu")
'
