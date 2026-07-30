*==============================================================================*
* test_driveuse.do -- battery for driveuse
* Run:  stata-mp -b do test_driveuse.do ["/path/to/pkg"]
* driveuse resolves the team's Google Drive shared-drive path per OS and sets
* $driveuse / $sf. The battery tests the resolver and the failure paths; it
* does not require the shared drive to be synced on this machine.
* Judge the run by the log: no r(NNN) errors, no "assertion is false".
*==============================================================================*
clear all
set more off
macro drop driveuse sf

if `"`1'"' != "" global pkgroot `"`1'"'
if `"$pkgroot"' == "" {
    capture findfile driveuse.ado
    if !_rc {
        local fp `"`r(fn)'"'
        local s = max(strrpos(`"`fp'"', "/"), strrpos(`"`fp'"', "\"))
        if `s' > 1 global pkgroot = substr(`"`fp'"', 1, `s' - 1)
    }
}
if `"$pkgroot"' == "" {
    di as err "test_driveuse: cannot locate driveuse.ado."
    exit 601
}
confirm file "$pkgroot/driveuse.ado"
adopath ++ "$pkgroot"
discard

*--- (1) bare call sets both globals ------------------------------------------*
driveuse
assert `"$driveuse"' != ""
assert `"$sf"' == `"$driveuse"'
di as res "TEST 1 OK: globals set to: $driveuse"

*--- (2) the resolved path targets the team shared drive ----------------------*
assert strpos(`"$driveuse"', "Shared drives") > 0
if "`c(os)'" == "MacOSX" {
    assert strpos(`"$driveuse"', "CloudStorage") > 0
}
di as res "TEST 2 OK: path shape is the shared-drive mount for `c(os)'"

*--- (3) a missing file fails loudly, not silently ----------------------------*
capture noisily driveuse using "zz_no_such_file_zz.dta", clear
assert _rc != 0
di as res "TEST 3 OK: missing file errors (rc " _rc ")"

*--- (4) rerun is idempotent --------------------------------------------------*
local before `"$driveuse"'
driveuse
assert `"$driveuse"' == `"`before'"'
di as res "TEST 4 OK: rerun leaves the same path"

di as res _n "ALL TESTS PASSED: driveuse battery complete"
