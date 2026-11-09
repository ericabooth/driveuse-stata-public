*! driveuse 1.0.1  Eric Booth  09nov2026
*! use a dataset from the team Google Drive shared drive, on macOS or Windows
*!
*! Syntax:
*!   driveuse [varlist using] filename [if] [in] [, clear nolabel]
*!   driveuse using filename [if] [in] [, clear nolabel]
*!   driveuse                          (only sets $driveuse and $sf)
*!
*! Changes:
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
    if inlist("`c(os)'", "MacOSX", "Unix") {
        local home : env HOME
        if `"`home'"' == "" local home "/Users/`c(username)'"
        local gd_base "`home'/Library/CloudStorage"
        mata: st_local("gdok", strofreal(direxists(st_local("gd_base"))))
        local folder ""
        if `gdok' {
            local folders : dir "`gd_base'" dirs "GoogleDrive-*"
            local folder  : word 1 of `folders'
            local folder  = subinstr(`"`folder'"', `"""', "", .)
        }
        if `"`folder'"' == "" {
            di as error "driveuse: no Google Drive mount found under `gd_base'"
            di as error "         (install Google Drive for Desktop and sign in)"
            exit 601
        }
        local sf_path "`gd_base'/`folder'/Shared drives/Data and Research Team"
    }
    else if "`c(os)'" == "Windows" {
        * Google Drive for Desktop mounts as a virtual drive, default G:
        local home : env USERPROFILE
        local sf_path "G:/Shared drives/Data and Research Team"
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
end
