# Byte Club Website

Website and home of the Byte Club. Let's get creative and make a welcoming place
where we can work together on our projects.

## Top Level Premise

We want the idea of hosts and guests for a self organizing grassroots style club.
- Hosts are the folks that name a time and place where they'll be working on a project
- Guests are the folks who sign up and join the host

We'd really like a high turnout percentage so that hosts can reliably know how many
folks are showing up. At some point, we'd like to have some system that can keep
track of that to keep folks honest.

## Other Ideas

This website could go anywhere. Here are some ideas
- A feed where folks can post their project demos
- Integration with Google Maps to post where the host is going
- Integration with the Zulip channel to notify of host locations
- Friends of byte club page to point folks to other programming clubs in Calgary
- Projects/languages/technologies heat map by user to get folks with similar
  interests in contact with each other

Any idea is welcome though. It's our website. We can make whatever we want!

# Development

The website uses the following tech stack
- [gleam lang](https://gleam.run/)
- [lustre frontend](https://github.com/lustre-labs/lustre)
- [wisp backend](https://github.com/gleam-wisp/wisp)

Tooling used
- [just](https://just.systems/) for command running
- [lefthook](https://evilmartians.com/opensource/lefthook) for git hooks
- [watchexec](https://watchexec.github.io/) for file watching

Common commands are documented in the [root justfile](./justfile)

The project has a simple structure
- [client](./client) is the frontend targetting javascript
- [server](./server) is well the server that we're hosting

