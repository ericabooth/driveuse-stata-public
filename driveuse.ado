*! driveuse 1.0.2  Eric Booth  09nov2026
*! use a dataset from the team Google Drive shared drive, on macOS or Windows
*!
*! Syntax:
*!   driveuse [varlist using] filename [if] [in] [, clear nolabel]
*!   driveuse using filename [if] [in] [, clear nolabel]
*!   driveuse                          (only sets $driveuse and $sf)
*!
*! Changes:
*!   1.0.2  09nov2026  with several Google Drive accounts mounted, use the
*!                     one that holds the shared drive (it used to take the
*!                     first GoogleDrive-* folder and set $sf to a path that
*!                     did not exist); Windows probes every drive letter
*!                     (G: first) instead of assuming G:; a missing shared
*!                     drive is an error even on a bare call; returns
*!                     r(path) (and r(file) after a load).
*!   1.0.1  09nov2026  if/in are passed to -use- instead of being glued onto
*!                     the file name; "driveuse using file" works; nolabel is
*!                     honoured; macOS home comes from HOME; a leading ~ in
*!                     the file name is expanded.
*!   1.0.0  21may2026  first public version.

program define driveuse, rclass
    version 14
    syntax [anything(everything)] [, CLEAR noLABel]

    * 1. Detect OS and set base paths
    * (Stata's console/batch build on macOS reports c(os) as "Unix", so
    *  treat both the same and detect the actual Drive mount instead.)
    local team "Shared drives/Data and Research Team"
    if inlist("`c(os)'", "MacOSX", "Unix") {
        local home : env HOME
        if `"`home'"' == "" local home "/Users/`c(username)'"
        local gd_base "`home'/Library/CloudStorage"
        mata: st_local("gdok", strofreal(direxists(st_local("gd_base"))))
        local folders ""
        if `gdok' {
            local folders : dir "`gd_base'" dirs "GoogleDrive-*"
            local folders : list sort folders
        }
        if `"`folders'"' == "" {
            di as error "driveuse: no Google Drive mount found under `gd_base'"
            di as error "         (install Google Drive for Desktop and sign in)"
            exit 601
        }
        * Several accounts can be mounted side by side.  Use the first one
        * (in sorted order) that actually holds the team shared drive.
        local sf_path ""
        foreach f of local folders {
            local cand "`gd_base'/`f'/`team'"
            mata: st_local("ok", strofreal(direxists(st_local("cand"))))
            if `ok' {
                local sf_path "`cand'"
                continue, break
            }
        }
        if `"`sf_path'"' == "" {
            di as error "driveuse: none of the Google Drive accounts under `gd_base'"
            di as error "         holds {bf:`team'}.  Accounts found:"
            foreach f of local folders {
                di as error "           `f'"
            }
            exit 601
        }
    }
    else if "`c(os)'" == "Windows" {
        * Google Drive for Desktop mounts as a virtual drive, default G:.
        * Probe G: first, then every other letter.
        local home : env USERPROFILE
        if `"`home'"' == "" {
            local hd : env HOMEDRIVE
            local hp : env HOMEPATH
            local home `"`hd'`hp'"'
        }
        local sf_path ""
        foreach L in G D E F H I J K L M N O P Q R S T U V W X Y Z {
            local cand "`L':/`team'"
            mata: st_local("ok", strofreal(direxists(st_local("cand"))))
            if `ok' {
                local sf_path "`cand'"
                continue, break
            }
        }
        if `"`sf_path'"' == "" {
            di as error "driveuse: no drive letter holds {bf:`team'}"
            di as error "         (is Google Drive for Desktop running and signed in?)"
            exit 601
        }
    }
    else {
        di as error "driveuse: unsupported operating system (`c(os)')"
        exit 198
    }

    * 2. Set global shortcuts
    global driveuse `"`sf_path'"'
    global sf `"`sf_path'"'

    * 3. Handle 'driveuse' called without arguments (just to set globals)
    if `"`macval(anything)'"' == "" {
        di as text "driveuse: globals {bf:\$driveuse} and {bf:\$sf} set to:"
        di as result `"`sf_path'"'
        return local path `"`sf_path'"'
        exit
    }

    * 4. Split  [varlist using] filename [if] [in]  token by token.
    *    Tokens before the first top-level -using-, -if- or -in- are the
    *    varlist (when -using- follows) or the file name (when it does not).
    *    Everything from -if-/-in- on is handed to -use- unchanged.
    local rest `"`macval(anything)'"'
    local pre ""
    local stop ""
    while `"`macval(rest)'"' != "" {
        local before `"`macval(rest)'"'
        gettoken tok rest : rest
        if `"`macval(tok)'"' == "using" {
            local stop using
            continue, break
        }
        if inlist(`"`macval(tok)'"', "if", "in") | ///
           substr(`"`macval(tok)'"', 1, 3) == "if(" {
            local stop ifin
            local rest `"`macval(before)'"'
            continue, break
        }
        local pre `"`macval(pre)' `macval(tok)'"'
    }
    local pre = strtrim(`"`macval(pre)'"')

    if "`stop'" == "using" {
        local vlist `"`macval(pre)'"'
        gettoken fname rest : rest
    }
    else {
        local vlist ""
        local fname `"`macval(pre)'"'
    }
    local ifin = strtrim(`"`macval(rest)'"')

    local fname = strtrim(`"`macval(fname)'"')
    if `"`macval(fname)'"' == "" {
        di as error "driveuse: no file name given"
        exit 198
    }

    * Expand a leading ~ from HOME (USERPROFILE on Windows)
    if `"`macval(fname)'"' == "~" | substr(`"`macval(fname)'"', 1, 2) == "~/" {
        if `"`home'"' == "" {
            di as error "driveuse: cannot expand ~ (HOME is not set)"
            exit 198
        }
        local tail = substr(`"`macval(fname)'"', 2, .)
        local fname `"`home'`macval(tail)'"'
    }

    * Prepend base path unless the name is already absolute
    local c1 = substr(`"`macval(fname)'"', 1, 1)
    if `"`c1'"' == "/" | `"`c1'"' == char(92) | ///
       regexm(`"`macval(fname)'"', "^[A-Za-z]:") {
        local fullpath `"`macval(fname)'"'
    }
    else {
        local fullpath `"`sf_path'/`macval(fname)'"'
    }

    * 5. Execute 'use'
    if `"`macval(vlist)'"' != "" {
        use `vlist' using `"`macval(fullpath)'"' `ifin', `clear' `label'
    }
    else {
        use `"`macval(fullpath)'"' `ifin', `clear' `label'
    }

    describe, short
    return local file `"`macval(fullpath)'"'
    return local path `"`sf_path'"'
end
