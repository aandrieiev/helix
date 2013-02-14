require 'helix/media'
require 'active_support/core_ext'

module Helix

  class Video < Media

    include DurationedMedia

    # The class name, to be used by supporting classes. Such as Config which uses
    # this method as a way to build URLs.
    #
    #
    # @example
    #   Helix::Video.media_type_sym #=> :video
    #
    # @return [Symbol] Name of the class.
    def self.media_type_sym; :video; end

    def self.slice(attrs={})
      rest_post(:slice, attrs)
    end


    # Used to retrieve a stillframe for a video by using
    # the video guid.
    #
    # @example
    #   sf_data = Helix::Video.get_stillframe("239c59483d346") #=> xDC\xF1?\xE9*?\xFF\xD9
    #   File.open("original.jpg", "w") { |f| f.puts sf_data }
    #
    # @param [String] guid is the string containing the guid for the video.
    # @param [Hash] opts a hash of options for building URL
    # @return [String] Stillframe jpg data, save it to a file with extension .jpg.
    def self.get_stillframe(guid, opts={})
      RestClient.log = 'helix.log' if opts.delete(:log)
      url = get_stillframe_url(guid, opts)
      RestClient.get(url)
    end

    def download
      url = config.build_url(action: :file, content_type: '', guid: guid, media_type: plural_media_type)
      RestClient.get(url, params: {signature: config.signature(:view)})
    end

    def play
      url = config.build_url(action: :play, content_type: '', guid: guid, media_type: plural_media_type)
      RestClient.get(url, params: {signature: config.signature(:view)})
    end

    def stillframe(opts={})
      self.class.get_stillframe(self.guid, opts)
    end

    private

    def self.get_stillframe_dimensions(opts)
      width   = opts[:width].to_s  + "w" unless opts[:width].nil?
      height  = opts[:height].to_s + "h" unless opts[:height].nil?
      width   = "original" if opts[:width].nil? && opts[:height].nil?
      [width, height]
    end

    def self.get_stillframe_url(guid, opts)
      server  = opts[:server] || config.credentials[:server] || "service-staging"
      width, height = get_stillframe_dimensions(opts)
      url     = "#{server}.twistage.com/videos/#{guid}/screenshots/"
      url    << "#{width.to_s}#{height.to_s}.jpg"
    end

  end
end
