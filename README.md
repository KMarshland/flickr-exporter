# Flick Export

This is a script to export Flickr photos including tags and albums, and then re-import them into lightroom.
Each stage can be run independently, so if your ultimate destination is not lightroom, you can still use the exporting tools.

## Installing
You'll need:
1. Ruby (tested with ruby 3; may work with older versions too)
2. A Flickr API key (see https://www.flickr.com/services/apps/create/noncommercial/)

Clone this repo, and then run `bundle install` to install the required gems.
Then, create a `.env` file with the following contents:

```text
FLICKR_API_KEY=your_api_key
FLICKR_API_SECRET=your_api_secret
```

## Usage

```bash
ruby run.rb help
```

