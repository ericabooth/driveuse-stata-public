{smcl}
{* *! version 1.0.2 09nov2026 Author: Eric A. Booth}{...}
{vieweralsosee "use" "help use"}{...}
{viewerjumpto "Syntax" "driveuse##syntax"}{...}
{viewerjumpto "Description" "driveuse##description"}{...}
{viewerjumpto "Options" "driveuse##options"}{...}
{viewerjumpto "Stored results" "driveuse##results"}{...}
{viewerjumpto "Author" "driveuse##author"}{...}
{hline}
Help file for {hi:driveuse}
{hline}

{title:Title}

{phang}
{bf:driveuse} {hline 2} Use datasets from Google Drive with cross-platform path handling


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:driveuse} {it:filename} [{it:if}] [{it:in}] [{cmd:,} {it:options}]

{phang2}
{cmd:driveuse} [{it:varlist}] {cmd:using} {it:filename} [{it:if}] [{it:in}] [{cmd:,} {it:options}]

{phang2}
{cmd:driveuse}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clear}}Replace data in memory{p_end}
{synopt:{opt nolabel}}Do not load value labels{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:driveuse} is a wrapper for {help use} that automatically detects the local path to Google Drive
on both macOS and Windows. It allows users to reference files relative to their Texas 2036 shared
drive folder ({cmd:Shared drives/Data and Research Team/}) without hardcoding local absolute paths.

{pstd}
On macOS, it searches for {cmd:Library/CloudStorage/GoogleDrive-*/Shared drives/Data and Research Team}.
When several Google Drive accounts are mounted, it uses the first account (in
sorted order) whose folder holds the shared drive. On Windows, it looks for
{cmd:Shared drives/Data and Research Team} on drive {cmd:G:} first and then on
every other drive letter. If no mount holds the shared drive, {cmd:driveuse}
stops with an error that lists the accounts it found, even when called without
arguments.

{pstd}
{cmd:driveuse} also creates two global macros that act as base folder shortcuts:
{break}  {bf:$driveuse} - The path to the shared drive base folder.
{break}  {bf:$sf} - (Short for "Source Files") An alias for the same path.

{pstd}
A relative {it:filename} is read from the shared-drive base folder. An absolute
{it:filename} (starting with {cmd:/}, a drive letter, or {cmd:\\}) is used as
given, and a leading {cmd:~} is expanded from {cmd:HOME} ({cmd:USERPROFILE} on
Windows). On macOS the home folder comes from the {cmd:HOME} environment
variable. The {it:if} and {it:in} qualifiers are passed to {help use}, so, as
with {cmd:use}, the variables named in {it:if} must be among those loaded.

{pstd}
These globals can be used to construct paths for other Stata commands like {help save}, {help export}, or {help do}.


{marker examples}{...}
{title:Examples}

{phang}1. Basic load from the shared drive base:{p_end}
{pmore}{cmd:. driveuse "mydata.dta", clear}{p_end}

{phang}2. Load from a subdirectory:{p_end}
{pmore}{cmd:. driveuse "ProjectA/data/raw_data.dta", clear}{p_end}

{phang}3. Load specific variables with an if condition:{p_end}
{pmore}{cmd:. driveuse id age region using "survey.dta" if region == 1, clear}{p_end}

{phang}3b. Load the first 100 observations, without value labels:{p_end}
{pmore}{cmd:. driveuse using "survey.dta" in 1/100, clear nolabel}{p_end}

{phang}4. Use the global shortcuts for other commands:{p_end}
{pmore}{cmd:. driveuse "raw.dta", clear}{p_end}
{pmore}{cmd:. gen newvar = 1}{p_end}
{pmore}{cmd:. save "$sf/processed/clean_data.dta", replace}{p_end}

{phang}5. Run driveuse without arguments just to initialize globals:{p_end}
{pmore}{cmd:. driveuse}{p_end}
{pmore}{cmd:. do "$sf/scripts/analysis.do"}{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt clear} permits the data to be loaded even if there is a dataset already in memory and even if that dataset has changed since it was last saved.

{phang}
{opt nolabel} prevents the loading of value labels.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:driveuse} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:r(path)}}the shared-drive base folder (the same as {bf:$sf}){p_end}
{synopt:{cmd:r(file)}}the full path of the file loaded (not set by a bare call){p_end}


{marker changes}{...}
{title:Changes}

{phang}1.0.2 (09nov2026): with several Google Drive accounts mounted,
{cmd:driveuse} uses the one that holds the shared drive instead of the first
{cmd:GoogleDrive-*} folder; Windows probes every drive letter, {cmd:G:} first;
a missing shared drive is an error even on a bare call; {cmd:r(path)} and
{cmd:r(file)} are returned.{p_end}

{phang}1.0.1 (09nov2026): {it:if} and {it:in} now reach {cmd:use} instead of being
read as part of the file name; {cmd:driveuse using} {it:filename} works;
{opt nolabel} is honoured; the macOS home folder comes from {cmd:HOME}; a
leading {cmd:~} is expanded.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}
