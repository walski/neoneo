module Neoneo
  module Utils
    class URL
      def self.url_unescape(string)
        string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
          [$1.delete('%')].pack('H*')
        end
      end
    end
  end
end