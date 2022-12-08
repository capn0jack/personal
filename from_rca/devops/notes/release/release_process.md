
Ensure all tickets to be released are in Waiting to Deploy status and assigned to DevOps staff.
In GitHub, compare sta with main.
Verify that all tickets that are waiting for release are in the diff.
Very that no tickets that are not waiting for release are in the diff.
Remediate, if necessary.
Generate PR from sta to main from the differences:
    Require PR approval from Dir., Engineering.
Once approved, merge PR.
Create a "release" in GitHub.  Until another plan has been conceived, the release versions are simply:
    Prefixed with "v".
    Concatenated with the date of the release in YYYYMMDD format.
    Suffixed with a period and the serial number of the release for that day.
    E.g. "v20211013.1"