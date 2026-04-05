# Notes

## Kill Claude Desktop processes

Claude Desktop needs to restart in order to use new/rebuild MCP.
Use the following command to kill all instances of claude-desktop process.

```shell
kill -9 $(ps aux | grep claude-desktop | grep -v grep | awk '{print $2}')
```
