# Capwagen

[Capistrano](https://github.com/capistrano/capistrano) integration for
[Kraftwagen](http://kraftwagen.org) based Drupal projects.

This brings single command, secure (SSH), multi-target deployments to
Drupal projects.  Capistrano is written in the [Ruby](http://ruby-lang.org)
programming language, but it has proven itself in the realm of PHP with
projects like [Capifony](http://capifony.org) (Capistrano for Symfony),
[capistrano-drupal](https://github.com/previousnext/capistrano-drupal) and
[WordPress Capistrano Deploy](https://github.com/nathanielks/Wordpress-Capistrano-Deploy).

Since Capistrano is so widely used, it has clearly proven to be a reliable
method of automating deployments.


## Assumptions

Capistrano is "opinionated software", it has very firm ideas about how
things ought to be done, and is not very flexible in that regard.
Some of the assumptions behind these opinions are:

* You use SSH to access the remote servers (so *no* native FTP support).
* You either have (1) the same password to all target machines, or (2)
  public keys in place to allow passwordless access (preferred).

If you cannot live with these assumptions, Capistrano is likely not
the right tool for you.


## Installation

Simple, but assumes you have Ruby version 1.8.7+, and the
[gems](http://rubygems.org) command available:

```
gem install capwagen
```


## Adding Capwagen to your project

```
cd /path/to/project/src
capwagen .
```

Now change `./cap/deploy.rb` to fit your configuration.


## Running a deployment

As easy as:

```
cd /path/top/project/src
cap deploy
```
