# frozen_string_literal: true

require 'bolder/scopes/scope'
require 'bolder/scopes/map'
require 'bolder/scopes/tree'

module Bolder
  class Scopes
    include Comparable

    def self.wrap(sc)
      if sc.respond_to?(:to_scopes)
        sc.to_scopes
      else
        new(sc)
      end
    end

    # @param scopes [Array<Scope, String>]
    def initialize(scopes)
      @scopes = [scopes].flatten.map { |s| Scope.wrap(s) }.sort{ |a, b| b <=> a}
    end

    # @return [Scopes]
    def to_scopes
      self
    end

    # Merge Scopes instances

    # @param another [Scopes]
    # @return [Scopes]
    def merge(another)
      raise ArgumentError, "Can't merge with #{another.class}" unless another.respond_to?(:to_scopes)
      another_scopes = another.to_scopes

      raise ArgumentError, "Can't merge with #{another.class}" unless another_scopes.is_a?(Scopes)

      self.class.new((scopes + another_scopes.scopes).uniq)
    end

    # Find first, most generic scope that matches given scope
    #
    # @param scope [Scope, String]
    # @return [Scope, nil]
    def resolve(scope)
      sc = Scope.wrap(scope)
      scopes.find { |s| s >= sc }
    end

    # @return [Boolean]
    def any?(&block)
      scopes.any? &block
    end

    # @return [Boolean]
    def all?(&block)
      scopes.all? &block
    end

    # @param another [Scopes, Scope, Array<Scope>]
    # @return [Boolean]
    def can?(another)
      another = self.class.wrap(another)
      !!scopes.find{|s1| another.any?{|s2| s1 >= s2}}
    end

    # Scope comparison. Implements Comparable
    # @param another [Scopes, Scope, Array<Scope>]
    # @return [Integer]
    def <=>(another)
      another = self.class.wrap(another)
      hit = scopes.find{|s1| another.all?{|s2| s1 >= s2}}
      hit ? 1 : -1
    end

    def inspect
      %(<#{self.class.name}##{object_id} [#{to_s}]>)
    end

    # Return a new [Scopes] with expanded scopes
    #
    # @example
    #   scopes = Scopes.new(['accounts.my-account', 'shops.my-shop'])
    #   scopes.expand('my-account' => 1, 'my-shop' => 2) # => Scopes.new(['accounts.1', 'shops.2'])
    #
    # @param attrs [Hash]
    # @return [Scopes]
    def expand(attrs = {})
      scp = scopes.map { |s| s.expand(attrs) }
      self.class.new(scp)
    end

    def to_s
      @to_s ||= scopes.join(', ')
    end

    def to_a
      @to_a ||= scopes.map &:to_s
    end

    protected

    attr_reader :scopes
  end
end
