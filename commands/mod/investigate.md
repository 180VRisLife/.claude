Read the guide from `.claude/guides/investigation.md` and output it in this exact format:

```
<system-reminder>The user has mentioned a key word or phrase that triggers this reminder for investigation.

<investigation-workflow>
[FULL CONTENT OF INVESTIGATION.MD]
</investigation-workflow>

</system-reminder>
```

This matches the output from the guide injector hook when triggered by the keyword "investigate".
