# yt-migrate

A simple tool to help migrate your YouTube likes and subscriptions between accounts. I
wrote this for personal use; maintenance isn't guaranteed, but I'm sharing it so others
may find it useful, if not just as a starting point for their own solution.

## Gotchas

- For some reason, some videos said that the creator disabled reactions, but I could like
  them manually in the UI. I could probably work around this by manually adding the videos
  to the "Liked Videos" playlist, but I didn't feel like it atm.
- If you have a lot of likes and subscriptions, you may run through the YouTube API limits.
  If this occurs, you'll have to wait until the next day to continue.

## Downloads

A Linux binary is available [here](https://drive.google.com/uc?export=download&id=1WubBvpsQPQ0Yul_z3CnZKDsR0q1fxHbf).

## Building

Install a recent version of the [Dart SDK](https://dart.dev/), then run:

```bash
$ pub get
$ dart2native -o yt-migrate bin/main.dart
```

to generate a standalone binary.

## Usage

You need a few things:

- A YouTube API key and credentials file. Follow
  [these directions](https://www.slickremix.com/docs/get-api-key-for-youtube/), but **STOP**
  at step 7. Instead, on the Credentials screen, select "YouTube Data API v3" under
  "Which API will you be using", and select "Other UI" under "Where will you be calling the API from?".
  Then select, "User data", click "What credentials do I need?", set the "Application type" to
  "Desktop app", give it a name, and hit "Create". From the next screen, click the small download
  icon next to your new credentials, and save the resulting credentials file somewhere safe.
- A takeout of your YouTube data from the old account, including likes and subs.

With all this, call the yt-migrate tool:

```bash
$ yt-migrate -c PATH-TO-MY-CREDENTIALS-FILE.json -t PATH-TO-TAKEOUT.ZIP -k
```

This will walk you through signing in to the target account, and it'll show you what's going to be
migrating before it starts. `-k` tells it to keep going on errors.

If you don't want to have to re-sign-in each time, pass `-C` with the path to some JSON file.
yt-migrate will create the file and store the authentication data inside, and once the file
already exists, it'll read it on subsequent runs and use it to sign in.
