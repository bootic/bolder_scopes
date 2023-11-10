# frozen_string_literal: true

module Bolder
  class Scopes
    # Maps of scopes
    # Example:
    #  map = Map.new('read' => ['read.users'])
    #  map.map('read') # => ['read.users']
    #  map.map('read:users') # => ['read.users']
    class Map
      # @param [Hash<#to_s, Array<#to_s>>] scope mapping
      def initialize(mapping = {})
        @mapping = mapping.each.with_object({}) { |(k, v), memo|
          memo[k.to_s] = Array(v).map(&:to_s)
        }
      end

      # Map scopes to aliases
      # Example:
      # map = Map.new('read' => ['read.users'])
      # map.map('read') # => ['read.users']
      #
      # @param [Array<String>] scopes
      # @return [Scopes]
      def map(scopes)
        scpes = Array(scopes.to_a).reduce([]){|memo, sc|
          memo + Array(@mapping.fetch(sc, sc))
        }.uniq

        Scopes.wrap(scpes)
      end

      # Expand scopes with aliases, including original scopes
      # Example:
      #
      # map = Map.new('read' => 'read.users')
      # map.expand('read') # => Scopes['read', 'read.users']
      #
      # @param [Array<String>] scopes
      # @return [Scopes]
      def expand(scopes)
        scopes = Array(scopes.to_a)
        registered_scopes = scopes.filter { |sc| @mapping.key?(sc) }
        result = registered_scopes + registered_scopes.reduce([]) { |memo, sc|
          memo + Array(@mapping.fetch(sc))
        }.uniq

        Scopes.wrap(result)
      end
    end
  end
end
