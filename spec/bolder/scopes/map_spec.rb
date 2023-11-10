# frozen_string_literal: true

require "spec_helper"
require 'bolder/scopes'

RSpec.describe Bolder::Scopes::Map do
  it 'maps aliases' do
    aliases = described_class.new(
      'admin' => %w[btc.me btc.account.shops.mine],
      'public' => %w[btc.me btc.shops.list.public]
    )

    scopes = aliases.map(%w[admin btc.foo.bar])
    expect(scopes).to be_a(Bolder::Scopes)
    expect(scopes).to match_array %w[btc.me btc.account.shops.mine btc.foo.bar]
  end

  it 'expands aliases preserving original scopes' do
    aliases = described_class.new(
      'admin' => %w[btc.me btc.account.shops.mine],
      'public' => %w[btc.me btc.shops.list.public]
    )

    scopes = aliases.expand(%w[admin btc.foo.bar])
    expect(scopes.to_a).to match_array %w[admin btc.me btc.account.shops.mine]
    expect(aliases.expand(%w[nope]).any?).to be(false)
  end

  it 'works with scope trees' do
    scopes = Bolder::Scopes::Tree.new('api') do
      admin
      me
      products do
        read
        write
      end
    end

    aliases = described_class.new(
      scopes.api.admin => [scopes.api.me, scopes.api.products],
      'guest' => [scopes.api.me]
    )

    expect(aliases.map(%w[api.admin])).to match_array %w[api.me api.products]
    expect(aliases.map(%w[guest])).to match_array %w[api.me]
    expect(aliases.map(%w[api.me])).to match_array %w[api.me]
  end
end
