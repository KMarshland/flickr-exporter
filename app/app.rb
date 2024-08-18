class App < Thor

  def self.exit_on_failure?
    true
  end

  desc 'get_manifest', 'Build a manifest of your Flickr photos, including tags and albums'
  option :skip_existing, type: :boolean, default: true, desc: 'Do not re-fetch metadata if it has already been fetched'
  def get_manifest
    flickr.build_manifest(skip_existing: options[:skip_existing])
  end

  desc 'download', 'Download all your Flickr photos based on the manifest'
  option :skip_manifest, type: :boolean, default: false, desc: 'Do not regenerate the manifest'
  option :skip_existing, type: :boolean, default: true, desc: 'Do not re-download files that already exist'
  def download
    flickr.build_manifest(skip_existing: options[:skip_existing]) unless options[:skip_manifest]
    flickr.download_photos(skip_existing: options[:skip_existing])
  end

  private

  def flickr
    @flickr ||= FlickrInterface.new
  end

end