
class FlickrInterface
  def initialize
    Flickr.cache = File.expand_path('./data/flickr_cache.yml')
    @flickr = Flickr.new(ENV['FLICKR_API_KEY'], ENV['FLICKR_SHARED_SECRET'])
    auth!
  end

  def auth!
    cache_file = File.expand_path('./data/flickrauth.json')
    if File.exist?(cache_file)
      flickr_auth = JSON.parse(File.read(cache_file))
      written_at = DateTime.parse(flickr_auth['written_at'])

      if written_at > 1.week.ago
        @flickr.access_token = flickr_auth['oauth_token']
        @flickr.access_secret = flickr_auth['oauth_token_secret']
        @user_id = CGI.unescape(flickr_auth['user_nsid'])

        begin
          @flickr.test.login
          return
        rescue Flickr::OAuthClient::FailedResponse
          puts "Failed to authenticate with Flickr. Please re-authenticate."
          File.delete(cache_file)
        end
      end
    end

    token = @flickr.get_request_token
    auth_url = @flickr.get_authorize_url(token['oauth_token'], :perms => 'read')

    puts "Open this url in your browser to complete the authentication process: #{auth_url}"
    puts "Copy here the number given when you complete the process."
    verify = gets.strip
    flickr_auth = @flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
    @user_id = CGI.unescape(flickr_auth['user_nsid'])

    flickr_auth['written_at'] = DateTime.now.iso8601

    File.write(cache_file, JSON.pretty_generate(flickr_auth))
  end

  def each_photo(page_size: 100)
    pages = nil

    (1..).each do |page|
      if pages
        puts "Fetching page #{page}/#{pages}"
      else
        puts "Fetching page #{page}"
      end

      search_args = {
        user_id: @user_id,
        sort: 'date-posted-asc',
        page: page,
        per_page: page_size,
        extras: 'tags',
        privacy_filter: 0
      }

      photos = @flickr.call('flickr.photos.search', search_args)
      pages ||= photos['pages']

      photos.each do |photo|
        yield photo
      end

      break if photos.size < page_size
    end
  end

  def tags_for(photo)
    @flickr.call('flickr.photos.getInfo', {photo_id: photo['id']})['tags'].to_a.map { |tag| tag['raw'] }
  end

  def file_url_for(photo)
    @flickr.call('flickr.photos.getSizes', {photo_id: photo['id']})['size'].find { |size| size['label'] == 'Original' }['source']
  end

  def album_names_for(photo)
    @flickr.call('flickr.photos.getAllContexts', {photo_id: photo['id']})['set'].to_a.map { |set| set['title'] }
  end

  def build_manifest(skip_existing: true)
    FileUtils.mkdir_p(File.expand_path('./data/manifest'))

    each_photo do |photo|
      manifest_file = File.expand_path("./data/manifest/#{photo['id']}.json")
      next if skip_existing && File.exist?(manifest_file)

      details = {
        **photo,
        'view_url' => "https://www.flickr.com/photos/#{photo['owner']}/#{photo['id']}",
        'tags' => tags_for(photo),
        'file_url' => file_url_for(photo),
        'album_names_for' => album_names_for(photo)
      }

      File.write(manifest_file, JSON.pretty_generate(details))
    end
  end

  def download_photos(skip_existing: true)
    manifest_files = Dir[File.expand_path('./data/manifest/*.json')]
    FileUtils.mkdir_p(File.expand_path('./data/photos'))

    manifest_files.each do |manifest_file|
      photo = JSON.parse(File.read(manifest_file))

      file_ext = photo['file_url'].split('.').last
      output_name = "#{photo['id']}.#{file_ext}"
      photo_file = File.expand_path("./data/photos/#{output_name}")

      if skip_existing && File.exist?(photo_file) && File.size(photo_file) > 0
        puts "Skipping #{photo['title']} (already downloaded)"
        next
      end

      puts "Downloading #{photo['title']} to #{output_name}"

      response = HTTP.get(photo['file_url'])
      raise "Failed to download #{photo['title']}" unless response.status.success?

      begin
        File.open(photo_file, 'wb') do |file|
          response.body.each do |chunk|
            file.write(chunk)
          end
        end
      rescue => e
        File.delete(photo_file)
        raise e
      end
    end
  end

end

if __FILE__ == $0
  flickr = FlickrInterface.new
  flickr.build_manifest
end





