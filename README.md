# Sophie
A [sophisticated copyright linter](https://github.com/aws/s2n-tls/issues/4078#issuecomment-1707031744) implemented as a portable UNIX shell script.

## Overview
Sophie handles your compliance checks by parsing a human-readable configuration file which means you can make simple to complex tests of legal standards across your project as easy as defining patterns and making statements.

Here's an example `sophie.config`:

```
filecabinet
	net_code[pattern="src/net_.*\.[ch]";]

notices
	net_code_author[literal="Copyright Netcode Author";]

compliance
	net_code_author_ip["net_code_author in net_code";]
```

Sophie can operate with minute details to ensure precise placement/structure of copyright notices, and defensively, leaving no room for any un-acknowledged intellectual property in your code.

