Read the guide from `.claude/guides/debug.md` and output it in this exact format:

```
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for debugging.

<debugging-workflow>
[FULL CONTENT OF DEBUG.MD]
</debugging-workflow>

</system-reminder>
```

This matches the output from the guide injector hook when triggered by the keyword "debug".
