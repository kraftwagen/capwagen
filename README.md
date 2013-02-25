# Capwagen

Capistrano integration for Kraftwagen projects. More information coming soon.
For the more adventurous of you a very short tutorial below.

* This is very inmature code at the moment. DO NOT use it for production 
deployments unless you do not care about breaking your production site.*

## Installation

```
gem install capwagen
```

## Adding Capwagen to your project

```
cd /path/to/project/src
capwagen .
```

Change `/path/to/project/src/cap/deploy.rb` to fit your configuration.

## Running a deployment

```
cd /path/top/project/src
cap deploy
```