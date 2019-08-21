require 'json'
require 'stringio'

module Bibliothecary
  module Parsers
    class Conda
      include Bibliothecary::Analyser

      def self.mapping
        {
          match_filename("environment.yml") => {
            parser: :parse_conda_manifest,
            multiple: true,
            kind: %w[manifest lockfile]
          },
          match_filename("environment.yaml") => {
            parser: :parse_conda_manifest,
            multiple: true,
            kind: %w[manifest lockfile]
          }
        }
      end

      def self.parse_conda_manifest(file_contents)
        manifest = parse_conda(file_contents)

        {
            "manifest" => map_dependencies(manifest, "manifest", "runtime"),
            "lockfile" => map_dependencies(manifest, "lockfile", "runtime"),
        }
      end

      def self.parse_conda(file_contents)
        host = Bibliothecary.configuration.conda_parser_host
        response = Typhoeus.post(
          "#{host}/parse",
          headers: {
              ContentType: 'multipart/form-data'
          },
          body: {file: file_contents, filename: 'environment.yml'}
        )
        raise Bibliothecary::RemoteParsingError.new("Http Error #{response.response_code} when contacting: #{host}/parse", response.response_code) unless response.success?

        JSON.parse(response.body)
      end
    end
  end
end