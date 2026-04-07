# Verify review findings before acting on them

Do not blindly accept automated review suggestions. Check whether the flagged
code path is actually reachable given callbacks, DB constraints, enums, etc.
Report false positives with evidence rather than adding unnecessary guards.
