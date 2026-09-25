# Custom Nushell Commands (sc-nu)

# Quick Look files (macOS)
export def ql [...files: path] {
    if ($files | is-empty) {
        print -e "Usage: ql <file> [<file> ...]"
        return 1
    }
    qlmanage -p ...$files err> /dev/null out> /dev/null
}

# Recursively remove .DS_Store files
export def "rm.dstore" [dir: path = "."] {
    let targets = (glob $"($dir)/**/.DS_Store")
    if ($targets | is-empty) {
        print "No .DS_Store files found."
        return
    }
    $targets | each { |f|
        rm -f $f
        print $"Removed: ($f)"
    }
}

# Fetch external WAN IPv4
export def "ip.wan" [] {
    try {
        http get https://api.ipify.org | str trim
    } catch {
        print -e "Failed to fetch external IP"
    }
}

# Fetch default network interface
export def "ip.if" [] {
    netstat -nr | lines | find "default" | find -v "fe80" | first | split row -r '\s+' | last
}

# Fetch default gateway IP
export def "ip.gw" [] {
    netstat -nr | lines | find "default" | find -v "fe80" | first | split row -r '\s+' | get 1
}

# Check HTTP status code
export def "http.chk" [url: string] {
    curl -o /dev/null -s -w "%{http_code}\n" $url
}


# Python virtual environment activator
export def --env activate [venv_dir: path = ".venv"] {
    let bin_dir = ($venv_dir | path join "bin" | path expand)
    if ($bin_dir | path exists) {
        $env.VIRTUAL_ENV = ($venv_dir | path expand)
        $env.PATH = ($env.PATH | split row (char esep) | prepend $bin_dir | uniq)
        print $"Activated virtual environment: ($env.VIRTUAL_ENV)"
    } else {
        print -e $"Virtual environment not found at ($venv_dir)"
        return 1
    }
}

# Python virtual environment deactivator
export def --env deactivate [] {
    if "VIRTUAL_ENV" in $env {
        let venv = $env.VIRTUAL_ENV
        let bin_dir = ($venv | path join "bin")
        $env.PATH = ($env.PATH | split row (char esep) | where { $in != $bin_dir })
        hide-env -i VIRTUAL_ENV
        print $"Deactivated virtualenv ($venv)"
    } else {
        print "No virtual environment is currently active"
    }
}
