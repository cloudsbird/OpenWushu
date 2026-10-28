require "net/http"

# Public details of a YouTube video from its oEmbed endpoint (no API key needed): the title, the
# channel, and whether the owner allows embedding (oEmbed answers 401 when they don't).
class YoutubeVideo
  ENDPOINT = "https://www.youtube.com/oembed".freeze

  Details = Data.define(:title, :author, :author_url)

  # Details, :not_embeddable, :not_found, or nil when YouTube can't be reached
  def self.lookup(id)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(url: "https://www.youtube.com/watch?v=#{id}", format: "json")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 3) { |http| http.get(uri.request_uri) }

    case response
    when Net::HTTPSuccess
      data = JSON.parse(response.body)
      Details.new(title: data["title"], author: data["author_name"], author_url: data["author_url"])
    when Net::HTTPUnauthorized, Net::HTTPForbidden then :not_embeddable
    when Net::HTTPNotFound, Net::HTTPBadRequest then :not_found
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError
    nil
  end
end
